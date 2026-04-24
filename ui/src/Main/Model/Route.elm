module Main.Model.Route exposing (..)

import AppUrl exposing (AppUrl, QueryParameters)
import Dict
import List.Extra as List
import Main.Config.App exposing (..)
import Main.Config.Package exposing (..)
import Main.Helpers.List as List
import Main.Helpers.Nix exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Preferences exposing (..)
import Set exposing (Set)
import String


{-| Description: a route is an address.
It is visible and usually shareable in the Web browser's URL bar.

Warning(security): it must not contain secret or sensitive data.

-}
type Route
    = Route_App RouteApp
    | Route_Apps RouteApps
    | Route_Packages RoutePackages
    | Route_RecipeOptions RouteRecipeOptions


type alias RouteApp =
    { routeApp_name : AppName
    , routeApp_runShown : Bool

    -- `Nothing` means to select the first available `AppRuntime`.
    -- The selected `AppRuntime` will then be in `pageApp_runtime`
    , routeApp_runRuntime : Maybe AppRuntime
    , routeApp_focus : Maybe RouteAppFocus
    }


defaultRouteApp : RouteApp
defaultRouteApp =
    { routeApp_name = ""
    , routeApp_runShown = False
    , routeApp_runRuntime = Nothing
    , routeApp_focus = Nothing
    }


type RouteAppFocus
    = RouteAppFocus_Resources
    | RouteAppFocus_Grants


showRouteAppFocus : RouteAppFocus -> String
showRouteAppFocus x =
    case x of
        RouteAppFocus_Resources ->
            "resources"

        RouteAppFocus_Grants ->
            "grants"


type alias RouteApps =
    { routeApps_search : String
    , routeApps_pagination : RoutePagination
    }


defaultRouteApps : RouteApps
defaultRouteApps =
    { routeApps_search = ""
    , routeApps_pagination = defaultRoutePagination
    }


type alias RoutePackages =
    { routePackages_search : String
    , routePackages_focus : Maybe RoutePackagesFocus
    , routePackages_pagination : RoutePagination
    }


defaultRoutePackages : RoutePackages
defaultRoutePackages =
    { routePackages_search = ""
    , routePackages_focus = Nothing
    , routePackages_pagination = defaultRoutePagination
    }


type RoutePackagesFocus
    = RoutePackagesFocus_Package PackageName


showRoutePackagesFocus : RoutePackagesFocus -> String
showRoutePackagesFocus x =
    case x of
        RoutePackagesFocus_Package s ->
            s


type alias RouteRecipeOptions =
    { routeRecipeOptions_searchPattern : String
    , routeRecipeOptions_focus : Maybe RouteRecipeOptionsFocus
    , routeRecipeOptions_scope : NixAttrPath
    , routeRecipeOptions_unfolds : Set NixAttrPath
    , routeRecipeOptions_pagination : RoutePagination
    }


type RouteRecipeOptionsFocus
    = RouteRecipeOptionsFocus_Option NixAttrPath


showRouteRecipeOptionsFocus : RouteRecipeOptionsFocus -> String
showRouteRecipeOptionsFocus x =
    case x of
        RouteRecipeOptionsFocus_Option s ->
            s |> joinNixAttrPath


defaultRouteRecipeOptions : RouteRecipeOptions
defaultRouteRecipeOptions =
    { routeRecipeOptions_searchPattern = ""
    , routeRecipeOptions_unfolds =
        Set.fromList
            [ [ "apps" ]
            , [ "packages" ]
            ]
    , routeRecipeOptions_scope = []
    , routeRecipeOptions_focus = Nothing
    , routeRecipeOptions_pagination = defaultRoutePagination
    }


type alias RoutePagination =
    { routePagination_current : Maybe Int
    , routePagination_MaxSize : Maybe Int
    }


defaultRoutePagination : RoutePagination
defaultRoutePagination =
    { routePagination_current = Nothing
    , routePagination_MaxSize = Nothing
    }


appUrlToRoutePagination : AppUrl -> RoutePagination
appUrlToRoutePagination url =
    { routePagination_current =
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
    , routePagination_MaxSize =
        url.queryParameters
            |> Dict.get "page-size"
            |> Maybe.andThen List.head
            |> Maybe.andThen String.toInt
            |> Maybe.andThen
                (\p ->
                    if p < 1 then
                        Nothing

                    else
                        Just p
                )
    }


routePaginationToQueryParameters : RoutePagination -> QueryParameters
routePaginationToQueryParameters routePagination =
    List.concat
        [ case routePagination.routePagination_current of
            Nothing ->
                []

            Just 1 ->
                []

            Just p ->
                [ ( "page", [ p |> String.fromInt ] ) ]
        , case routePagination.routePagination_MaxSize of
            Nothing ->
                []

            Just p ->
                [ ( "page-size", [ p |> String.fromInt ] ) ]
        ]
        |> Dict.fromList


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


appUrlToRoute : AppUrl -> Result ErrorRoute Route
appUrlToRoute url =
    case url.path |> List.drop (List.length deployPath) of
        [] ->
            Ok <|
                Route_Apps
                    { routeApps_search = ""
                    , routeApps_pagination = url |> appUrlToRoutePagination
                    }

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

                        Just "run-nixos" ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = True
                                , routeApp_runRuntime = Just AppRuntime_NixOS
                            }

                        Just "run" ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = True
                            }

                        Just focusId ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = False
                                , routeApp_focus =
                                    case focusId of
                                        "resources" ->
                                            Just RouteAppFocus_Resources

                                        "grants" ->
                                            Just RouteAppFocus_Grants

                                        _ ->
                                            Nothing
                            }

                        Nothing ->
                            { defaultRouteApp
                                | routeApp_name = appName
                                , routeApp_runShown = False
                            }

        [ "apps" ] ->
            Ok <|
                Route_Apps <|
                    case url.queryParameters |> Dict.get "q" |> Maybe.andThen List.uncons of
                        Nothing ->
                            { routeApps_search = ""
                            , routeApps_pagination = url |> appUrlToRoutePagination
                            }

                        Just ( q, _ ) ->
                            { routeApps_search = q
                            , routeApps_pagination = url |> appUrlToRoutePagination
                            }

        [ "packages" ] ->
            Ok <|
                Route_Packages <|
                    case url.queryParameters |> Dict.get "q" |> Maybe.andThen List.uncons of
                        Nothing ->
                            { defaultRoutePackages
                                | routePackages_search = ""
                                , routePackages_pagination = url |> appUrlToRoutePagination
                                , routePackages_focus =
                                    url.fragment
                                        |> Maybe.map
                                            (\fragment ->
                                                case fragment of
                                                    packageName ->
                                                        RoutePackagesFocus_Package packageName
                                            )
                            }

                        Just ( q, _ ) ->
                            { defaultRoutePackages | routePackages_search = q }

        [ "recipe", "options" ] ->
            Ok <|
                let
                    scope =
                        url.queryParameters
                            |> Dict.get "s"
                            |> Maybe.andThen List.head
                            |> Maybe.withDefault ""
                            |> splitNixAttrId

                    focus =
                        url.fragment
                            |> Maybe.map
                                (\fragment ->
                                    case fragment of
                                        optionId ->
                                            RouteRecipeOptionsFocus_Option (optionId |> splitNixAttrId)
                                )

                    unfolds =
                        url.queryParameters
                            |> Dict.get "p"
                            |> Maybe.withDefault []
                            |> List.map splitNixAttrId
                            |> Set.fromList
                in
                Route_RecipeOptions
                    { routeRecipeOptions_searchPattern =
                        url.queryParameters
                            |> Dict.get "q"
                            |> Maybe.andThen List.head
                            |> Maybe.withDefault ""
                    , routeRecipeOptions_scope = scope
                    , routeRecipeOptions_unfolds = unfolds
                    , routeRecipeOptions_pagination = url |> appUrlToRoutePagination
                    , routeRecipeOptions_focus = focus
                    }

        _ ->
            Err (ErrorRoute_Unknown url)


routeToAppUrl : Route -> AppUrl
routeToAppUrl route =
    case route of
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

                                            AppRuntime_NixOS ->
                                                "-nixos"
                               )
                        )

                else
                    routeApp.routeApp_focus
                        |> Maybe.map showRouteAppFocus
            }

        Route_Apps routeApps ->
            case routeApps.routeApps_search of
                "" ->
                    { path = deployPath
                    , queryParameters =
                        Dict.empty
                            |> Dict.union (routePaginationToQueryParameters routeApps.routeApps_pagination)
                    , fragment = Nothing
                    }

                q ->
                    { path = deployPath ++ [ "apps" ]
                    , queryParameters =
                        [ ( "q", [ q ] ) ]
                            |> Dict.fromList
                            |> Dict.union (routePaginationToQueryParameters routeApps.routeApps_pagination)
                    , fragment = Nothing
                    }

        Route_Packages routePackages ->
            { path = deployPath ++ [ "packages" ]
            , queryParameters =
                [ ( "q"
                  , case routePackages.routePackages_search of
                        "" ->
                            []

                        q ->
                            [ q ]
                  )
                ]
                    |> Dict.fromList
                    |> Dict.union (routePaginationToQueryParameters routePackages.routePackages_pagination)
            , fragment =
                routePackages.routePackages_focus
                    |> Maybe.map
                        (\focus ->
                            case focus of
                                RoutePackagesFocus_Package s ->
                                    s
                        )
            }

        Route_RecipeOptions routeRecipe ->
            { path = deployPath ++ [ "recipe", "options" ]
            , queryParameters =
                let
                    unfolds : Set NixAttrPath
                    unfolds =
                        routeRecipe.routeRecipeOptions_unfolds
                            |> Set.remove routeRecipe.routeRecipeOptions_scope
                            |> (case routeRecipe.routeRecipeOptions_focus of
                                    Just (RouteRecipeOptionsFocus_Option optionPath) ->
                                        Set.remove optionPath

                                    _ ->
                                        identity
                               )

                    unfoldsWithoutAncestors : Set NixAttrPath
                    unfoldsWithoutAncestors =
                        unfolds
                            |> Set.toList
                            |> List.foldl
                                (\optionPath acc ->
                                    Set.diff acc
                                        (optionPath
                                            |> List.dropLast
                                            |> Maybe.withDefault []
                                            |> List.inits
                                            |> Set.fromList
                                        )
                                )
                                unfolds
                in
                [ ( "p"
                  , case unfoldsWithoutAncestors |> Set.toList of
                        [] ->
                            []

                        xs ->
                            xs |> List.map joinNixAttrPath
                  )
                , ( "q"
                  , case routeRecipe.routeRecipeOptions_searchPattern of
                        "" ->
                            []

                        q ->
                            [ q ]
                  )
                , ( "s"
                  , case routeRecipe.routeRecipeOptions_scope |> List.filter ((/=) "") of
                        [] ->
                            []

                        xs ->
                            [ xs |> joinNixAttrPath ]
                  )
                ]
                    |> Dict.fromList
                    |> Dict.union (routePaginationToQueryParameters routeRecipe.routeRecipeOptions_pagination)
            , fragment =
                routeRecipe.routeRecipeOptions_focus
                    |> Maybe.map
                        (\focus ->
                            case focus of
                                RouteRecipeOptionsFocus_Option s ->
                                    s |> joinNixAttrPath
                        )
            }


routeToString : Route -> String
routeToString =
    routeToAppUrl >> AppUrl.toString
