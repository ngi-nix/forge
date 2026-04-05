module Main.Config.App exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Main.Helpers.String exposing (..)


type alias App =
    { app_name : AppName
    , app_description : String
    , app_usage : String
    , app_programs : AppPrograms
    , app_container : AppContainer
    , app_vm : AppNixosVm
    , app_ngi : Ngi
    , app_links : AppLinks
    }


app_output : App -> String
app_output app =
    app.app_name ++ "-app"


type alias AppPrograms =
    { enable : Bool
    }


type alias AppContainer =
    { enable : Bool
    }


type alias AppNixosVm =
    { enable : Bool
    }


type alias AppName =
    String


getAppIconPath : AppName -> String
getAppIconPath appName =
    "resources/apps/" ++ appName ++ "/icon.svg"


getDefaultIconPath : String
getDefaultIconPath =
    "resources/apps/app-icon.svg"


decodeApp : Decoder App
decodeApp =
    Decode.map8 App
        (Decode.field "name" decodeAppName)
        (Decode.field "description" Decode.string)
        (Decode.field "usage" Decode.string)
        (Decode.field "programs" decodeAppPrograms)
        (Decode.field "container" decodeAppContainer)
        (Decode.field "nixos" decodeAppNixosVm)
        (Decode.field "ngi" decodeNgi)
        (Decode.field "links" decodeAppLinks)


decodeAppName : Decoder AppName
decodeAppName =
    Decode.string
        |> Decode.andThen
            (\s ->
                if String.length s > 0 && String.all (\c -> 'a' <= c && c <= 'z' || 'A' <= c && c <= 'Z' || '0' <= c && c <= '9' || c == '-' || c == '_') s then
                    Decode.succeed <| stripSuffix "-app" <| s

                else
                    Decode.fail <| "Invalid application name: " ++ s
            )


decodeAppPrograms : Decoder AppPrograms
decodeAppPrograms =
    Decode.map AppPrograms
        (Decode.field "enable" Decode.bool)


decodeAppContainer : Decoder AppContainer
decodeAppContainer =
    Decode.map AppContainer
        (Decode.field "enable" Decode.bool)


decodeAppNixosVm : Decoder AppNixosVm
decodeAppNixosVm =
    Decode.map AppNixosVm
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


type alias AppLinks =
    { website : Maybe String
    , docs : Maybe String
    , source : Maybe String
    }


decodeAppLinks : Decoder AppLinks
decodeAppLinks =
    Decode.map3 AppLinks
        (Decode.maybe (Decode.at [ "website", "url" ] Decode.string))
        (Decode.maybe (Decode.at [ "docs", "url" ] Decode.string))
        (Decode.maybe (Decode.at [ "source", "url" ] Decode.string))


type AppRuntime
    = AppRuntime_Shell
    | AppRuntime_Container
    | AppRuntime_VM


listAppRuntimeAvailable : App -> List AppRuntime
listAppRuntimeAvailable app =
    [ if app.app_programs.enable then
        [ AppRuntime_Shell ]

      else
        []
    , if app.app_container.enable then
        [ AppRuntime_Container ]

      else
        []
    , if app.app_vm.enable then
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


type LinkType
    = Link_Source
    | Link_Docs
    | Link_Website


showAppLink : LinkType -> String
showAppLink r =
    case r of
        Link_Website ->
            "Homepage"

        Link_Docs ->
            "Documentation"

        Link_Source ->
            "Source Repository"
