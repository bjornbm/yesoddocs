{-# LANGUAGE TemplateHaskell, QuasiQuotes, OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
module Handler.Root
    ( getRootR
    , getPageR
    ) where

import Wiki
import Handler.Topic (getTopicR)
import Text.Hamlet.NonPoly (html)
import Util (renderContent)

getRootR :: Handler RepHtml
getRootR = do
    mpage <- runDB $ getBy $ UniquePage ""
    mcontent <-
        case mpage of
            Nothing -> return Nothing
            Just (_, Page { pageTopic = tid }) -> runDB $ do
                x <- selectList [TopicContentTopicEq tid] [TopicContentChangedDesc] 1 0
                case x of
                    [] -> return Nothing
                    (_, TopicContent {..}):_ -> return $ Just (topicContentFormat, topicContentContent)
    let html' =
            case mcontent of
                Nothing -> [html|
<h1>No homepage set.
<p>The site admin has no yet set a homepage topic.
|]
                Just (format, content) -> renderContent format content
    defaultLayout $ addHtml html'

getPageR :: Text -> Handler RepHtml
getPageR t = do
    p <- runDB $ getBy404 (UniquePage t)
    getTopicR $ pageTopic $ snd p
