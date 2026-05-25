module Main.Config.Repository exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Main.Helpers.String exposing (..)


type alias Repository =
    { repository_archiveUrl : String
    , repository_commitRef : String
    , repository_gitUrl : String
    , repository_homeUrl : String
    , repository_nixUrl : String
    , repository_nixUrlLatest : String
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
    , repository_nixUrlLatest = ""
    , repository_path = ""
    , repository_treeUrl = ""
    }


decodeRepository : Decoder Repository
decodeRepository =
    Decode.map8 Repository
        (Decode.field "archiveUrl" Decode.string)
        (Decode.field "commitRef" Decode.string)
        (Decode.field "gitUrl" Decode.string)
        (Decode.field "homeUrl" Decode.string)
        (Decode.field "nixUrl" Decode.string)
        (Decode.field "nixUrlLatest" Decode.string)
        (Decode.field "path" Decode.string)
        (Decode.field "treeUrl" Decode.string)
