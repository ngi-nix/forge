module Main.Config exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import List
import Main.Config.App as Config exposing (..)
import Main.Config.Package as Config exposing (..)
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
    , config_recipe : ConfigRecipe
    , config_apps : Dict AppName App
    , config_packages : Dict PackageName Package
    }


initConfig : Config
initConfig =
    { config_repository = "github:ngi-nix/forge"
    , config_recipe = initRecipe
    , config_apps = Dict.empty
    , config_packages = Dict.empty
    }


decodeConfig : Decoder Config
decodeConfig =
    Decode.map4 Config
        (Decode.field "repositoryUrl" Decode.string)
        (Decode.field "recipeDirs" decodeConfigRecipe)
        (Decode.field "apps" (Decode.dict Config.decodeApp))
        (Decode.field "packages" (Decode.dict Config.decodePackage))


type alias ConfigRecipe =
    { configRecipe_apps : Directory
    , configRecipe_packages : Directory
    }


initRecipe : ConfigRecipe
initRecipe =
    { configRecipe_apps = ""
    , configRecipe_packages = ""
    }


decodeConfigRecipe : Decoder ConfigRecipe
decodeConfigRecipe =
    Decode.map2 ConfigRecipe
        (Decode.field "apps" decodeDirectory)
        (Decode.field "packages" decodeDirectory)


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
