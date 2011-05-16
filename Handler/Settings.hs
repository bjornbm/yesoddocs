{-# LANGUAGE TemplateHaskell, QuasiQuotes, OverloadedStrings #-}
module Handler.Settings
    ( getSettingsR
    , postSettingsR
    ) where

import Wiki

form' :: Text -> Handler ((FormResult Text, Widget ()), Enctype)
form' = runFormPost . renderTable . areq textField (FieldSettings MsgYourName Nothing Nothing Nothing) . Just

getSettingsR :: Handler RepHtml
getSettingsR = do
    (uid, user) <- requireAuth
    ((_, form), enctype) <- form' $ userName user
    maps <- runDB $ selectList [TMapOwnerEq uid] [] 0 0
    topics <- runDB $ selectList [TopicOwnerEq uid] [] 0 0
    defaultLayout $(widgetFile "settings")

postSettingsR :: Handler ()
postSettingsR = do
    uid <- requireAuthId
    ((res, _), _) <- form' ""
    case res of
        FormSuccess name -> do
            runDB $ update uid [UserName name]
            setMessageI MsgSettingsUpdated
        _ -> return ()
    redirect RedirectTemporary SettingsR
