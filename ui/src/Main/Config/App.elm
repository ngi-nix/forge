module Main.Config.App exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Main.Helpers.Json.Decode as Decode


type alias App =
    { app_name : AppName
    , app_outputName : AppName
    , app_displayName : String
    , app_description : String
    , app_usage : String
    , app_programs : AppPrograms
    , app_services : AppServices
    , app_ngi : Ngi
    , app_links : AppLinks
    , app_recipePath : String
    , app_maintainers : List Maintainer
    }


decodeApp : Decoder App
decodeApp =
    App
        |> Decode.flipMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "outputName" Decode.string)
        |> Decode.andMap (Decode.field "displayName" Decode.string)
        |> Decode.andMap (Decode.field "description" Decode.string)
        |> Decode.andMap (Decode.field "usage" Decode.string)
        |> Decode.andMap (Decode.field "programs" decodeAppPrograms)
        |> Decode.andMap (Decode.field "services" decodeAppServices)
        |> Decode.andMap (Decode.field "ngi" decodeNgi)
        |> Decode.andMap (Decode.field "links" decodeAppLinks)
        |> Decode.andMap (Decode.field "recipePath" Decode.string)
        |> Decode.andMap (Decode.field "maintainers" (Decode.list decodeMaintainer))


type alias AppName =
    String


type alias AppProgramsRuntimesProgram =
    { enable : Bool
    }


type alias AppProgramsRuntimesShell =
    { enable : Bool
    }


type alias AppProgramsRuntimes =
    { appProgramsRuntimes_program : AppProgramsRuntimesProgram
    , appProgramsRuntimes_shell : AppProgramsRuntimesShell
    }


type alias AppPrograms =
    { appPrograms_runtimes : AppProgramsRuntimes
    , appPrograms_runProgram : String
    , appPrograms_packages : List String
    , appPrograms_mainPackage : Maybe String
    }


decodeAppPrograms : Decoder AppPrograms
decodeAppPrograms =
    Decode.map4 AppPrograms
        (Decode.field "runtimes" decodeAppProgramsRuntimes)
        (Decode.field "runProgram" Decode.string)
        (Decode.field "packages" (Decode.list Decode.string))
        (Decode.field "mainPackage" (Decode.nullable Decode.string))


decodeAppProgramsRuntimes : Decoder AppProgramsRuntimes
decodeAppProgramsRuntimes =
    Decode.map2 AppProgramsRuntimes
        (Decode.field "program" decodeAppProgramsRuntimesProgram)
        (Decode.field "shell" decodeAppProgramsRuntimesShell)


decodeAppProgramsRuntimesProgram : Decoder AppProgramsRuntimesProgram
decodeAppProgramsRuntimesProgram =
    Decode.map AppProgramsRuntimesProgram
        (Decode.field "enable" Decode.bool)


decodeAppProgramsRuntimesShell : Decoder AppProgramsRuntimesShell
decodeAppProgramsRuntimesShell =
    Decode.map AppProgramsRuntimesShell
        (Decode.field "enable" Decode.bool)


type alias AppResource =
    { appResource_ports : List String
    }


decodeAppResource : Decoder AppResource
decodeAppResource =
    Decode.map AppResource
        (Decode.field "ports" (Decode.list Decode.string))


type alias AppComponent =
    { appComponent_ports : List String
    , appComponent_resources : Dict String AppResource
    }


decodeAppComponent : Decoder AppComponent
decodeAppComponent =
    Decode.map2 AppComponent
        (Decode.field "process" (Decode.field "ports" (Decode.list Decode.string)))
        (Decode.field "resources" (Decode.dict decodeAppResource))


type alias AppServices =
    { appServices_components : Dict String AppComponent
    , appServices_runtimes : AppServicesRuntimes
    }


decodeAppServices : Decoder AppServices
decodeAppServices =
    Decode.map2 AppServices
        (Decode.field "components" (Decode.dict decodeAppComponent))
        (Decode.field "runtimes" decodeAppServicesRuntimes)


decodeAppServicesRuntimes : Decoder AppServicesRuntimes
decodeAppServicesRuntimes =
    Decode.map2 AppServicesRuntimes
        (Decode.field "container" decodeAppServicesRuntimesContainer)
        (Decode.field "nixos" decodeAppServicesRuntimesNixos)


type alias AppServicesRuntimes =
    { appServicesRuntimes_container : AppServicesRuntimesContainer
    , appServicesRuntimes_nixos : AppServicesRuntimesNixos
    }


type alias AppServicesRuntimesContainer =
    { enable : Bool
    }


decodeAppServicesRuntimesContainer : Decoder AppServicesRuntimesContainer
decodeAppServicesRuntimesContainer =
    Decode.map AppServicesRuntimesContainer
        (Decode.field "enable" Decode.bool)


type alias AppServicesRuntimesNixos =
    { enable : Bool
    }


decodeAppServicesRuntimesNixos : Decoder AppServicesRuntimesNixos
decodeAppServicesRuntimesNixos =
    Decode.map AppServicesRuntimesNixos
        (Decode.field "enable" Decode.bool)


decodeAppContainer : Decoder AppServicesRuntimesContainer
decodeAppContainer =
    Decode.map AppServicesRuntimesContainer
        (Decode.field "enable" Decode.bool)


decodeAppNixos : Decoder AppServicesRuntimesNixos
decodeAppNixos =
    Decode.map AppServicesRuntimesNixos
        (Decode.field "enable" Decode.bool)


type alias Ngi =
    { ngi_grants : NgiGrants
    }


decodeNgi : Decoder Ngi
decodeNgi =
    Decode.map Ngi
        (Decode.field "grants" decodeNgiGrants)


type alias NgiGrants =
    Dict NgiGrantName NgiSubgrants


type alias NgiGrantName =
    String


decodeNgiGrants : Decoder NgiGrants
decodeNgiGrants =
    Decode.dict (Decode.list Decode.string)


type alias NgiSubgrants =
    List NgiSubgrantName


type alias NgiSubgrantName =
    String


type AppRuntime
    = AppRuntime_Program
    | AppRuntime_Shell
    | AppRuntime_Container
    | AppRuntime_NixOS


hasAppRuntime : AppRuntime -> App -> Bool
hasAppRuntime appRuntime app =
    case appRuntime of
        AppRuntime_Program ->
            app.app_programs.appPrograms_runtimes.appProgramsRuntimes_program.enable

        AppRuntime_Shell ->
            app.app_programs.appPrograms_runtimes.appProgramsRuntimes_shell.enable

        AppRuntime_Container ->
            app.app_services.appServices_runtimes.appServicesRuntimes_container.enable

        AppRuntime_NixOS ->
            app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable


listAppRuntime : List AppRuntime
listAppRuntime =
    [ AppRuntime_Program
    , AppRuntime_Shell
    , AppRuntime_Container
    , AppRuntime_NixOS
    ]


listAppRuntimeAvailable : App -> List AppRuntime
listAppRuntimeAvailable app =
    [ if app.app_programs.appPrograms_runtimes.appProgramsRuntimes_program.enable then
        [ AppRuntime_Program ]

      else
        []
    , if app.app_programs.appPrograms_runtimes.appProgramsRuntimes_shell.enable then
        [ AppRuntime_Shell ]

      else
        []
    , if app.app_services.appServices_runtimes.appServicesRuntimes_container.enable then
        [ AppRuntime_Container ]

      else
        []
    , if app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
        [ AppRuntime_NixOS ]

      else
        []
    ]
        |> List.concat


showAppRuntime : AppRuntime -> String
showAppRuntime r =
    case r of
        AppRuntime_Program ->
            "Program"

        AppRuntime_Shell ->
            "Shell"

        AppRuntime_Container ->
            "Container"

        AppRuntime_NixOS ->
            "NixOS"


type alias AppLinks =
    { appLinks_docs : Maybe String
    , appLinks_source : Maybe String
    , appLinks_website : Maybe String
    }


decodeAppLinks : Decoder AppLinks
decodeAppLinks =
    Decode.map3 AppLinks
        (Decode.maybe (Decode.field "docs" Decode.string))
        (Decode.maybe (Decode.field "source" Decode.string))
        (Decode.maybe (Decode.field "website" Decode.string))


storePathToName : String -> String
storePathToName path =
    let
        basename =
            path |> String.split "/" |> List.reverse |> List.head |> Maybe.withDefault path

        -- Nix store basenames are "<32-char-hash>-<name>", drop hash and separator
        hashLength =
            33
    in
    String.dropLeft hashLength basename


getAppProgramPackageNames : AppPrograms -> List String
getAppProgramPackageNames programs =
    let
        main =
            programs.appPrograms_mainPackage |> Maybe.map List.singleton |> Maybe.withDefault []
    in
    (main ++ programs.appPrograms_packages)
        |> List.map storePathToName
        |> List.sort
        |> deduplicate


deduplicate : List String -> List String
deduplicate =
    List.foldr
        (\x acc ->
            if List.member x acc then
                acc

            else
                x :: acc
        )
        []


getAppServicesPorts : AppServices -> List String
getAppServicesPorts services =
    services.appServices_components
        |> Dict.toList
        |> List.concatMap
            (\( _, component ) ->
                component.appComponent_ports
                    ++ (component.appComponent_resources
                            |> Dict.toList
                            |> List.concatMap (Tuple.second >> .appResource_ports)
                       )
            )


type alias Maintainer =
    { maintainer_name : String
    , maintainer_github : Maybe String
    , maintainer_email : Maybe String
    }


decodeMaintainer : Decoder Maintainer
decodeMaintainer =
    Decode.map3 Maintainer
        (Decode.field "name" Decode.string)
        (Decode.maybe (Decode.field "github" Decode.string))
        (Decode.maybe (Decode.field "email" Decode.string))
