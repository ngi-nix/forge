module Main.Config.Package exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Main.Config.App exposing (..)
import Main.Helpers.Json.Decode as Decode
import Main.Helpers.String exposing (..)


type alias Package =
    { package_pname : PackageName
    , package_outputName : PackageName
    , package_description : String
    , package_version : String
    , package_homePage : String
    , package_mainProgram : String
    , package_licenses : List PackageLicense
    , package_source : PackageSource
    , package_recipePath : String
    , package_maintainers : List Maintainer
    }


decodePackage : Decoder Package
decodePackage =
    Package
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


type alias PackageName =
    String


type alias PackageSource =
    { source_git : Maybe String
    , source_url : Maybe String
    , source_path : Maybe String
    , source_hash : String
    , source_patches : List String
    }


decodeSource : Decoder PackageSource
decodeSource =
    Decode.map5 PackageSource
        (Decode.field "git" (Decode.maybe Decode.string))
        (Decode.field "url" (Decode.maybe Decode.string))
        (Decode.field "path" (Decode.maybe Decode.string))
        (Decode.field "hash" Decode.string)
        (Decode.field "patches" (Decode.list Decode.string))


type alias PackageLicense =
    { license_deprecated : Maybe Bool
    , license_free : Maybe Bool
    , license_fullName : Maybe String
    , license_redistributable : Maybe Bool
    , license_shortName : Maybe String
    , license_spdxId : Maybe String
    , license_url : Maybe String
    }


decodeLicenses : Decoder (List PackageLicense)
decodeLicenses =
    Decode.oneOf
        [ Decode.list decodePackageLicense
        , Decode.map List.singleton decodePackageLicense
        ]


decodePackageLicense : Decoder PackageLicense
decodePackageLicense =
    Decode.map7 PackageLicense
        (Decode.maybe (Decode.field "deprecated" Decode.bool))
        (Decode.maybe (Decode.field "free" Decode.bool))
        (Decode.maybe (Decode.field "fullName" Decode.string))
        (Decode.maybe (Decode.field "redistributable" Decode.bool))
        (Decode.maybe (Decode.field "shortName" Decode.string))
        (Decode.maybe (Decode.field "spdxId" Decode.string))
        (Decode.maybe (Decode.field "url" Decode.string))
