{-# LANGUAGE TemplateHaskell, QuasiQuotes, OverloadedStrings #-}
module Handler.Feed
    ( getFeedR
    , getFeedItemR
    ) where

import Wiki
import Yesod.Feed

getFeedR :: Handler RepAtomRss
getFeedR = do
    now <- liftIO getCurrentTime
    entries <- runDB $ selectList [] [Desc NewsItemCreated, LimitTo 30] >>= (mapM $ \(nid, n) -> return FeedEntry
        { feedEntryLink = FeedItemR nid
        , feedEntryUpdated = newsItemCreated n
        , feedEntryTitle = newsItemTitle n
        , feedEntryContent = newsItemContent n
        })

    newsFeed Feed
        { feedTitle = "Yesod Wiki"
        , feedLinkSelf = FeedR
        , feedLinkHome = RootR
        , feedDescription = ""
        , feedLanguage = "en"
        , feedUpdated = now
        , feedEntries = entries
        }

getFeedItemR :: NewsItemId -> Handler ()
getFeedItemR nid = do
    NewsItem { newsItemUrl = url } <- runDB $ get404 nid
    redirectText RedirectPermanent url
