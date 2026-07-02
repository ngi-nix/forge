module Main.Config.Pkg exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Main.Config.App exposing (..)
import Main.Helpers.Json.Decode as Decode
import Main.Helpers.String exposing (..)


type alias Pkg =
    { pkg_pname : PkgName
    , pkg_outputName : PkgName
    , pkg_description : String
    , pkg_version : String
    , pkg_homePage : String
    , pkg_mainProgram : String
    , pkg_licenses : List PkgLicense
    , pkg_source : PkgSource
    , pkg_recipePath : String
    , pkg_maintainers : List Maintainer
    }


decodePkg : Decoder Pkg
decodePkg =
    Pkg
        |> Decode.flipMap (Decode.field "pname" Decode.string)
        |> Decode.andMap (Decode.field "outputName" Decode.string)
        |> Decode.andMap (Decode.field "description" Decode.string)
        |> Decode.andMap (Decode.field "version" Decode.string)
        |> Decode.andMap (Decode.field "homePage" Decode.string)
        |> Decode.andMap (Decode.field "mainProgram" Decode.string)
        |> Decode.andMap (Decode.field "license" decodeLicenses)
        |> Decode.andMap (Decode.field "source" decodeSource)
        |> Decode.andMap (Decode.field "recipePath" Decode.string)
        |> Decode.andMap (Decode.field "maintainers" (Decode.list decodeMaintainer))


type alias PkgName =
    String


type alias PkgSource =
    { source_git : Maybe String
    , source_url : Maybe String
    , source_path : Maybe String
    , source_hash : String
    , source_patches : List String
    }


decodeSource : Decoder PkgSource
decodeSource =
    Decode.map5 PkgSource
        (Decode.field "git" (Decode.maybe Decode.string))
        (Decode.field "url" (Decode.maybe Decode.string))
        (Decode.field "path" (Decode.maybe Decode.string))
        (Decode.field "hash" Decode.string)
        (Decode.field "patches" (Decode.list Decode.string))


type alias PkgLicense =
    { license_deprecated : Maybe Bool
    , license_free : Maybe Bool
    , license_fullName : Maybe String
    , license_redistributable : Maybe Bool
    , license_shortName : Maybe String
    , license_spdxId : Maybe String
    , license_url : Maybe String
    }


decodeLicenses : Decoder (List PkgLicense)
decodeLicenses =
    Decode.oneOf
        [ Decode.list decodePkgLicense
        , Decode.map List.singleton decodePkgLicense
        ]


decodePkgLicense : Decoder PkgLicense
decodePkgLicense =
    Decode.map7 PkgLicense
        (Decode.maybe (Decode.field "deprecated" Decode.bool))
        (Decode.maybe (Decode.field "free" Decode.bool))
        (Decode.maybe (Decode.field "fullName" Decode.string))
        (Decode.maybe (Decode.field "redistributable" Decode.bool))
        (Decode.maybe (Decode.field "shortName" Decode.string))
        (Decode.maybe (Decode.field "spdxId" Decode.string))
        (Decode.maybe (Decode.field "url" Decode.string))
