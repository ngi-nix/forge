module AppStore.Select exposing (..)

import AppStore.Config exposing (..)
import AppStore.Config.App exposing (..)
import AppStore.Select.Model exposing (..)
import AppStore.Select.Update exposing (..)
import AppStore.Select.View exposing (..)
import Dict
import Http


initSelect : () -> ( ModelSelect, Cmd UpdateSelect )
initSelect _ =
    ( { repositoryUrl = "github:imincik/nix-forge"
      , recipeDirApps = ""
      , apps = Dict.empty
      , selectedApp = Nothing
      , searchString = ""
      , error = Nothing
      }
    , getConfig
    )


getConfig : Cmd UpdateSelect
getConfig =
    Http.get
        { url = "/forge-config.json"
        , expect = Http.expectJson UpdateSelect_GetConfig configDecoder
        }
