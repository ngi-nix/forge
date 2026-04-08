module Main.Config.App exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Main.Helpers.String exposing (..)


type alias App =
    { app_name : AppName
    , app_description : String
    , app_usage : String
    , app_programs : AppPrograms
    , app_services : AppServices
    , app_ngi : Ngi
    , app_links : AppLinks
    }


app_output : App -> String
app_output app =
    app.app_name ++ "-app"


decodeApp : Decoder App
decodeApp =
    Decode.map7 App
        (Decode.field "name" (Decode.string |> Decode.map (stripSuffix "-app")))
        (Decode.field "description" Decode.string)
        (Decode.field "usage" Decode.string)
        (Decode.field "programs" decodeAppPrograms)
        (Decode.field "services" decodeAppServices)
        (Decode.field "ngi" decodeNgi)
        (Decode.field "links" decodeAppLinks)


type alias AppName =
    String


type alias AppPrograms =
    { enable : Bool
    }


decodeAppPrograms : Decoder AppPrograms
decodeAppPrograms =
    Decode.map AppPrograms
        (Decode.field "enable" Decode.bool)


type alias AppServices =
    { appServices_runtimes : AppServicesRuntimes
    }


decodeAppServices : Decoder AppServices
decodeAppServices =
    Decode.map AppServices
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


getAppIconPath : AppName -> String
getAppIconPath appName =
    "resources/apps/" ++ appName ++ "/icon.svg"


getDefaultIconPath : String
getDefaultIconPath =
    "resources/apps/app-icon.svg"


decodeAppContainer : Decoder AppServicesRuntimesContainer
decodeAppContainer =
    Decode.map AppServicesRuntimesContainer
        (Decode.field "enable" Decode.bool)


decodeAppNixosVm : Decoder AppServicesRuntimesNixos
decodeAppNixosVm =
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
    = AppRuntime_Shell
    | AppRuntime_Container
    | AppRuntime_VM


hasAppRuntime : AppRuntime -> App -> Bool
hasAppRuntime appRuntime app =
    case appRuntime of
        AppRuntime_Shell ->
            app.app_programs.enable

        AppRuntime_Container ->
            app.app_services.appServices_runtimes.appServicesRuntimes_container.enable

        AppRuntime_VM ->
            app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable


listAppRuntime : List AppRuntime
listAppRuntime =
    [ AppRuntime_Shell
    , AppRuntime_Container
    , AppRuntime_VM
    ]


listAppRuntimeAvailable : App -> List AppRuntime
listAppRuntimeAvailable app =
    [ if app.app_programs.enable then
        [ AppRuntime_Shell ]

      else
        []
    , if app.app_services.appServices_runtimes.appServicesRuntimes_container.enable then
        [ AppRuntime_Container ]

      else
        []
    , if app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
        [ AppRuntime_VM ]

      else
        []
    ]
        |> List.concat


showAppRuntime : AppRuntime -> String
showAppRuntime r =
    case r of
        AppRuntime_Shell ->
            "Shell"

        AppRuntime_Container ->
            "Container"

        AppRuntime_VM ->
            "VM"


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
