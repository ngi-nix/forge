module Main.Config exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Main.Config.App as Config exposing (..)
import Main.Config.Package as Config exposing (..)
import Main.Config.Repository as Config exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model.Error exposing (..)


type alias Config =
    { config_apps : Dict AppName App
    , config_packages : Dict PackageName Package
    , config_repository : Repository
    }


initConfig : Config
initConfig =
    { config_apps = Dict.empty
    , config_packages = Dict.empty
    , config_repository = Config.initRepository
    }


decodeConfig : Decoder Config
decodeConfig =
    Decode.map3 Config
        (Decode.field "apps" (Decode.dict Config.decodeApp))
        (Decode.field "packages" (Decode.dict Config.decodePackage))
        (Decode.field "repository" decodeRepository)


type alias Path =
    String


decodePath : Decoder Path
decodePath =
    Decode.string


type alias Directory =
    Path


decodeDirectory : Decoder Directory
decodeDirectory =
    decodePath
