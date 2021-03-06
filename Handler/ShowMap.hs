{-# LANGUAGE TemplateHaskell, QuasiQuotes, OverloadedStrings #-}
module Handler.ShowMap
    ( getShowMapR
    , getShowMapTopicR
    , loadTree
    , showTree
    , loadTreeNode
    ) where

import Wiki
import Handler.Topic (getTopicR)
import Util (renderContent)
import Database.Persist.GenericSql (SqlPersist)
import Text.Hamlet (HtmlUrl, hamlet)

data Tree = Tree
    { treeTopicId :: Maybe TopicId -- FIXME TMapNodeId
    , treeTitle :: Text
    , treeContent :: Maybe TopicContent
    , treeChildren :: [Tree]
    }

showTree :: Int -> [Tree] -> HtmlUrl WikiRoute
showTree depth trees = [hamlet|
$forall tree <- trees
    <section>
        $maybe tid <- treeTopicId tree
            <h1 #topic-#{toSinglePiece tid}>
                <a .topic-link href=@{TopicR tid}>#{treeTitle tree}
        $nothing
            <h1>#{treeTitle tree}
        $maybe c <- treeContent tree
            $maybe tid <- treeTopicId tree
                ^{renderContent tid (topicContentFormat c) (topicContentContent c)}
        ^{showTree (incr depth) $ treeChildren tree}
|]
  where
    incr 6 = 6
    incr i = i + 1

loadTree :: TMapId -> Handler [Tree]
loadTree = runDB . loadTree'

loadTree' :: TMapId -> SqlPersist (GGHandler sub Wiki IO) [Tree]
loadTree' tmid =
    selectList [TMapNodeMap ==. tmid, TMapNodeParent ==. Nothing] [Asc TMapNodePosition] >>= (fmap concat . mapM loadTreeNode)

loadTreeNode :: (TMapNodeId, TMapNode) -> SqlPersist (GGHandler sub Wiki IO) [Tree]
loadTreeNode (tmnid, tmn) = do
    case tMapNodeCmap tmn of
        Nothing -> do
            c <- selectList [TMapNodeParent ==. Just tmnid] [Asc TMapNodePosition] >>= mapM loadTreeNode
            title <-
                case tMapNodeCtopic tmn of
                    Nothing -> return ""
                    Just tid -> do
                        t <- get404 tid
                        return $ topicTitle t
            content <-
                case tMapNodeCtopic tmn of
                    Nothing -> return Nothing
                    Just tid -> do
                        x <- selectList [TopicContentTopic ==. tid] [Desc TopicContentChanged, LimitTo 1]
                        case x of
                            (_, y):_ -> return $ Just y
                            [] -> return Nothing
            return [Tree
                { treeTopicId = tMapNodeCtopic tmn
                , treeTitle = title
                , treeChildren = concat c
                , treeContent = content
                }]
        Just tmid -> loadTree' tmid

getShowMapR :: TMapId -> Handler RepHtml
getShowMapR tmid = do
    tree <- loadTree tmid
    defaultLayout $(widgetFile "show-map")

getShowMapTopicR :: TMapId -> TopicId -> Handler RepHtml
getShowMapTopicR _tmid topicid = getTopicR topicid
