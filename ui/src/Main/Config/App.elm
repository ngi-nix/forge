module Main.Config.App exposing (..)

import Json.Decode as Decode exposing (Decoder)


type alias App =
    { app_name : AppName
    , app_description : String
    , app_usage : String
    , app_programs : AppPrograms
    , app_container : AppContainer
    , app_vm : AppNixosVm
    , app_ngi : AppNgi
    , app_links : AppLinks
    }


type alias AppNgi =
    { grants : AppNgiSubgrants
    }


type alias AppPrograms =
    { enable : Bool
    }


type alias AppContainer =
    { enable : Bool
    }


type alias AppNixosVm =
    { enable : Bool
    }


type alias AppNgiSubgrants =
    { commons : List String
    , core : List String
    , entrust : List String
    , review : List String
    }


type alias AppLinks =
    { website : Maybe String
    , docs : Maybe String
    , source : Maybe String
    }


type alias AppName =
    String


stripAppSuffix : AppName -> String
stripAppSuffix name =
    let
        suffix =
            "-app"
    in
    if String.endsWith suffix name then
        String.dropRight (String.length suffix) name

    else
        name


decodeApp : Decoder App
decodeApp =
    Decode.map8 App
        (Decode.field "name" decodeAppName)
        (Decode.field "description" Decode.string)
        (Decode.field "usage" Decode.string)
        (Decode.field "programs" decodeAppPrograms)
        (Decode.field "container" decodeAppContainer)
        (Decode.field "nixos" decodeAppNixosVm)
        (Decode.field "ngi" decodeAppNgi)
        (Decode.field "links" decodeAppLinks)


decodeAppName : Decoder AppName
decodeAppName =
    Decode.string
        |> Decode.andThen
            (\s ->
                if String.length s > 0 && String.all (\c -> 'a' <= c && c <= 'z' || 'A' <= c && c <= 'Z' || '0' <= c && c <= '9' || c == '-' || c == '_') s then
                    -- remove -app suffix
                    Decode.succeed <| stripAppSuffix s

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


decodeAppNgi : Decoder AppNgi
decodeAppNgi =
    Decode.map AppNgi
        (Decode.field "grants" decodeAppNgiSubgrants)


decodeAppNgiSubgrants : Decoder AppNgiSubgrants
decodeAppNgiSubgrants =
    Decode.map4 AppNgiSubgrants
        (Decode.field "Commons" (Decode.list Decode.string))
        (Decode.field "Core" (Decode.list Decode.string))
        (Decode.field "Entrust" (Decode.list Decode.string))
        (Decode.field "Review" (Decode.list Decode.string))


decodeAppLinks : Decoder AppLinks
decodeAppLinks =
    Decode.map3 AppLinks
        (Decode.maybe (Decode.at [ "website", "url" ] Decode.string))
        (Decode.maybe (Decode.at [ "docs", "url" ] Decode.string))
        (Decode.maybe (Decode.at [ "source", "url" ] Decode.string))


type AppOutput
    = AppOutput_Shell
    | AppOutput_Container
    | AppOutput_VM


showAppOutput : AppOutput -> String
showAppOutput r =
    case r of
        AppOutput_Shell ->
            "Shell"

        AppOutput_Container ->
            "Container"

        AppOutput_VM ->
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
