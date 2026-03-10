module AppStore.Select.Model exposing (..)

import AppStore.Config exposing (..)
import AppStore.Config.App exposing (..)
import Dict exposing (Dict)


type alias ModelSelect =
    { repositoryUrl : String
    , recipeDirApps : String
    , apps : Dict String App
    , selectedApp : Maybe App
    , searchString : String
    , error : Maybe String
    }
