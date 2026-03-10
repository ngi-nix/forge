module NixForge.Select exposing (..)

import Dict
import Http
import NixForge.Config exposing (..)
import NixForge.Config.App exposing (..)
import NixForge.Select.Model exposing (..)
import NixForge.Select.Update exposing (..)
import NixForge.Select.View exposing (..)


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
