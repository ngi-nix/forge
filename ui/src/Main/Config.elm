module Main.Config exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Main.Config.App as Config exposing (..)
import Main.Config.Package as Config exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model.Error exposing (..)


type alias Config =
    { config_repository : Repository
    , config_apps : Dict AppName App
    , config_packages : Dict PackageName Package
    }


initConfig : Config
initConfig =
    { config_repository = initRepository
    , config_apps = Dict.empty
    , config_packages = Dict.empty
    }


decodeConfig : Decoder Config
decodeConfig =
    Decode.map3 Config
        (Decode.field "repository" decodeRepository)
        (Decode.field "apps" (Decode.dict Config.decodeApp))
        (Decode.field "packages" (Decode.dict Config.decodePackage))


type alias Repository =
    { repository_archiveUrl : String
    , repository_commitRef : String
    , repository_gitUrl : String
    , repository_homeUrl : String
    , repository_nixUrl : String
    , repository_path : String
    , repository_treeUrl : String
    }


initRepository : Repository
initRepository =
    { repository_archiveUrl = ""
    , repository_commitRef = ""
    , repository_gitUrl = ""
    , repository_homeUrl = ""
    , repository_nixUrl = ""
    , repository_path = ""
    , repository_treeUrl = ""
    }


decodeRepository : Decoder Repository
decodeRepository =
    Decode.map7 Repository
        (Decode.field "archiveUrl" Decode.string)
        (Decode.field "commitRef" Decode.string)
        (Decode.field "gitUrl" Decode.string)
        (Decode.field "homeUrl" Decode.string)
        (Decode.field "nixUrl" Decode.string)
        (Decode.field "path" Decode.string)
        (Decode.field "treeUrl" Decode.string)


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
