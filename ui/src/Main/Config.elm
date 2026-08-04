module Main.Config exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Main.Config.App as Config exposing (..)
import Main.Config.Pkg as Config exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model.Error exposing (..)
import Url exposing (Url)


commit : String
commit =
    "master"


{-| Note: master is < 8 chars
-}
shortCommit : String
shortCommit =
    String.left 8 commit


{-| Warning(portability): `Url` only supports HTTP(s) protocol.
-}
type alias UrlHttp =
    Url


type alias Config =
    { config_repository : NixUrl
    , config_apps : Dict AppName App
    , config_pkgs : Dict PkgName Pkg
    }


initConfig : Config
initConfig =
    { config_repository = "github:ngi-nix/forge"
    , config_apps = Dict.empty
    , config_pkgs = Dict.empty
    }


decodeConfig : Decoder Config
decodeConfig =
    Decode.map3 Config
        (Decode.field "repositoryUrl" Decode.string)
        (Decode.field "apps" (Decode.dict Config.decodeApp))
        (Decode.field "pkgs" (Decode.dict Config.decodePkg))
