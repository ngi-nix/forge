module Main.Route exposing (..)

import AppUrl exposing (AppUrl)
import Dict
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Config.App exposing (..)
import Main.Error exposing (..)
import Main.Helpers.Nix exposing (..)


{-| Description: a route is an address.
It is visible and usually shareable in the Web browser's URL bar.

Warning(security): it must not contain secret or sensitive data.

-}
type Route
    = Route_Search RouteSearch
    | Route_App RouteApp
    | Route_RecipeOptions RouteRecipeOptions


type alias RouteSearch =
    { routeSearch_pattern : String
    }


type alias RouteApp =
    { routeApp_name : AppName
    , routeApp_runShown : Bool

    -- `Nothing` means to select the first available `AppRuntime`.
    -- The selected `AppRuntime` will then be in `pageApp_runtime`
    , routeApp_runRuntime : Maybe AppRuntime
    , routeApp_focusWidget : Maybe String
    }


defaultRouteApp : RouteApp
defaultRouteApp =
    { routeApp_name = ""
    , routeApp_runShown = False
    , routeApp_runRuntime = Nothing
    , routeApp_focusWidget = Nothing
    }


type alias RouteRecipeOptions =
    { routeRecipeOptions_pattern : Maybe NixName
    , routeRecipeOptions_page : Maybe Int
    , routeRecipeOptions_MaxResultsPerPage : Maybe Int
    , routeRecipeOptions_option : Maybe String
    }


defaultRouteRecipeOptions : RouteRecipeOptions
defaultRouteRecipeOptions =
    { routeRecipeOptions_pattern = Nothing
    , routeRecipeOptions_page = Nothing
    , routeRecipeOptions_MaxResultsPerPage = Nothing
    , routeRecipeOptions_option = Nothing
    }


{-| BUILD TIME CONFIG:
replaced with deployment root in github workflow script eg. "/forge/"
-}
deployRoot : String
deployRoot =
    ":baseUrl"


deployPath : List String
deployPath =
    deployRoot
        |> String.split "/"
        |> List.filter (\seg -> seg /= "" && seg /= ":" ++ "baseUrl")


fromAppUrl : AppUrl -> Result ErrorRoute Route
fromAppUrl url =
    case url.path |> List.drop (List.length deployPath) of
        [] ->
            Ok (Route_Search { routeSearch_pattern = "" })

        [ "app" ] ->
            case url.queryParameters |> Dict.get "q" |> Maybe.andThen List.uncons of
                Nothing ->
                    Ok (Route_Search { routeSearch_pattern = "" })

                Just ( q, _ ) ->
                    Ok (Route_Search { routeSearch_pattern = q })

        [ "app", appName ] ->
            Ok <|
                Route_App <|
                    case url.fragment of
                        Just "run-shell" ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = True
                                , routeApp_runRuntime = Just AppRuntime_Shell
                            }

                        Just "run-container" ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = True
                                , routeApp_runRuntime = Just AppRuntime_Container
                            }

                        Just "run-vm" ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = True
                                , routeApp_runRuntime = Just AppRuntime_VM
                            }

                        Just "run" ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = True
                            }

                        Just targetId ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = False
                                , routeApp_focusWidget = Just targetId
                            }

                        Nothing ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = False
                            }

        [ "recipe", "options" ] ->
            Ok
                (Route_RecipeOptions
                    { routeRecipeOptions_pattern =
                        url.queryParameters
                            |> Dict.get "q"
                            |> Maybe.andThen List.head
                    , routeRecipeOptions_page =
                        url.queryParameters
                            |> Dict.get "page"
                            |> Maybe.andThen List.head
                            |> Maybe.andThen String.toInt
                            |> Maybe.andThen
                                (\p ->
                                    if p < 1 then
                                        Nothing

                                    else
                                        Just p
                                )
                    , routeRecipeOptions_MaxResultsPerPage =
                        url.queryParameters
                            |> Dict.get "MaxResultsPerPage"
                            |> Maybe.andThen List.head
                            |> Maybe.andThen String.toInt
                            |> Maybe.andThen
                                (\p ->
                                    if p < 1 then
                                        Nothing

                                    else
                                        Just p
                                )
                    , routeRecipeOptions_option =
                        url.fragment
                    }
                )

        _ ->
            Err (ErrorRoute_Unknown url)


toAppUrl : Route -> AppUrl
toAppUrl route =
    case route of
        Route_Search routeSearch ->
            case routeSearch.routeSearch_pattern of
                "" ->
                    { path = deployPath
                    , queryParameters = Dict.empty
                    , fragment = Nothing
                    }

                q ->
                    { path = deployPath ++ [ "app" ]
                    , queryParameters = [ ( "q", [ q ] ) ] |> Dict.fromList
                    , fragment = Nothing
                    }

        Route_App routeApp ->
            { path = deployPath ++ [ "app", routeApp.routeApp_name ]
            , queryParameters = Dict.empty
            , fragment =
                if routeApp.routeApp_runShown then
                    Just
                        ("run"
                            ++ (case routeApp.routeApp_runRuntime of
                                    Nothing ->
                                        ""

                                    Just output ->
                                        case output of
                                            AppRuntime_Shell ->
                                                "-shell"

                                            AppRuntime_Container ->
                                                "-container"

                                            AppRuntime_VM ->
                                                "-vm"
                               )
                        )

                else
                    Nothing
            }

        Route_RecipeOptions routeRecipe ->
            { path = deployPath ++ [ "recipe", "options" ]
            , queryParameters =
                [ ( "q"
                  , case routeRecipe.routeRecipeOptions_pattern of
                        Nothing ->
                            []

                        Just "" ->
                            []

                        Just q ->
                            [ q ]
                  )
                , ( "page"
                  , case routeRecipe.routeRecipeOptions_page of
                        Nothing ->
                            []

                        Just p ->
                            [ p |> String.fromInt ]
                  )
                , ( "MaxResultsPerPage"
                  , case routeRecipe.routeRecipeOptions_MaxResultsPerPage of
                        Nothing ->
                            []

                        Just p ->
                            [ p |> String.fromInt ]
                  )
                ]
                    |> Dict.fromList
            , fragment = routeRecipe.routeRecipeOptions_option
            }


toString : Route -> String
toString =
    toAppUrl >> AppUrl.toString
