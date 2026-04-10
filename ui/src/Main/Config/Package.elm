module Main.Config.Package exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Main.Helpers.String exposing (..)


type alias Package =
    { package_name : PackageName
    , package_description : String
    , package_version : String
    , package_homePage : String
    , package_mainProgram : String
    , package_license : PackageLicense
    , package_source : PackageSource
    }


decodePackage : Decoder Package
decodePackage =
    Decode.map7 Package
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "version" Decode.string)
        (Decode.field "homePage" Decode.string)
        (Decode.field "mainProgram" Decode.string)
        (Decode.field "license" decodeLicense)
        (Decode.field "source" decodeSource)


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
    { license_deprecated : Bool
    , license_free : Bool
    , license_fullName : String
    , license_redistributable : Bool
    , license_shortName : String
    , license_spdxId : String
    , license_url : String
    }


decodeLicense : Decoder PackageLicense
decodeLicense =
    Decode.map7 PackageLicense
        (Decode.field "deprecated" Decode.bool)
        (Decode.field "free" Decode.bool)
        (Decode.field "fullName" Decode.string)
        (Decode.field "redistributable" Decode.bool)
        (Decode.field "shortName" Decode.string)
        (Decode.field "spdxId" Decode.string)
        (Decode.field "url" Decode.string)
