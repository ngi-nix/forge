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


type alias Category =
    { category_name : String
    , category_description : String
    }


type alias Config =
    { config_repository : NixUrl
    , config_apps : Dict AppName App
    , config_pkgs : Dict PkgName Pkg
    , config_categories : Dict String Category
    }


initConfig : Config
initConfig =
    { config_repository = "github:ngi-nix/forge"
    , config_apps = Dict.empty
    , config_pkgs = Dict.empty
    , config_categories = Dict.empty
    }


decodeCategory : Decoder Category
decodeCategory =
    Decode.map2 Category
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)


decodeConfig : Decoder Config
decodeConfig =
    Decode.map4 Config
        (Decode.field "repositoryUrl" Decode.string)
        (Decode.field "apps" (Decode.dict Config.decodeApp))
        (Decode.field "pkgs" (Decode.dict Config.decodePkg))
        (Decode.field "categories" (Decode.dict decodeCategory))
