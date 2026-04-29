module Main.Config.Package exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Main.Helpers.String exposing (..)


type alias Package =
    { package_name : PackageName
    , package_description : String
    , package_version : String
    , package_homePage : String
    , package_mainProgram : String
    , package_licenses : List PackageLicense
    , package_source : PackageSource
    , package_recipePath : String
    }


decodePackage : Decoder Package
decodePackage =
    Decode.map8 Package
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "version" Decode.string)
        (Decode.field "homePage" Decode.string)
        (Decode.field "mainProgram" Decode.string)
        (Decode.field "license" decodeLicenses)
        (Decode.field "source" decodeSource)
        (Decode.field "recipePath" Decode.string)


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
