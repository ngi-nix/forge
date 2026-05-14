module Main.Config.App exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Main.Helpers.Json.Decode as Decode


type alias App =
    { app_name : AppName
    , app_displayName : String
    , app_description : String
    , app_usage : String
    , app_programs : AppPrograms
    , app_services : AppServices
    , app_ngi : Ngi
    , app_links : AppLinks
    , app_recipePath : String
    }


decodeApp : Decoder App
decodeApp =
    App
        |> Decode.flipMap (Decode.field "name" Decode.string)
        |> Decode.andMap (Decode.field "displayName" Decode.string)
        |> Decode.andMap (Decode.field "description" Decode.string)
        |> Decode.andMap (Decode.field "usage" Decode.string)
        |> Decode.andMap (Decode.field "programs" decodeAppPrograms)
        |> Decode.andMap (Decode.field "services" decodeAppServices)
        |> Decode.andMap (Decode.field "ngi" decodeNgi)
        |> Decode.andMap (Decode.field "links" decodeAppLinks)
        |> Decode.andMap (Decode.field "recipePath" Decode.string)


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
    , appPrograms_runCommand : String
    }


decodeAppPrograms : Decoder AppPrograms
decodeAppPrograms =
    Decode.map2 AppPrograms
        (Decode.field "runtimes" decodeAppProgramsRuntimes)
        (Decode.field "runCommand" Decode.string)


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


type alias AppServices =
    { appServices_ports : List String
    , appServices_runtimes : AppServicesRuntimes
    }


decodeAppServices : Decoder AppServices
decodeAppServices =
    Decode.map2 AppServices
        (Decode.field "ports" (Decode.list Decode.string))
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
        (Decode.maybe (Decode.at [ "docs", "url" ] Decode.string))
        (Decode.maybe (Decode.at [ "source", "url" ] Decode.string))
        (Decode.maybe (Decode.at [ "website", "url" ] Decode.string))
