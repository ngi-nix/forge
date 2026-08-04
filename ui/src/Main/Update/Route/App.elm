module Main.Update.Route.App exposing (..)

import Dict
import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Cmd as Cmd
import Main.Helpers.Nix exposing (..)
import Main.Helpers.String as String
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.Navigation
import Main.Ports.SmoothScroll exposing (..)
import Main.Update.Config exposing (..)
import Main.Update.Focus exposing (..)
import Main.Update.Route.Recipe exposing (..)
import Main.Update.Types exposing (..)
import Maybe.Extra as Maybe
import Navigation


updateRouteApp : RouteApp -> Updater
updateRouteApp route =
    getConfig <|
        \model ->
            case
                [ route.routeApp_name

                -- If no app is matching retry by removing the `-app` suffix
                -- which was used for namespacing apps amongst other `allSystems.${system}.packages`
                -- in `ngi-forge-0.1`.
                , String.stripSuffix "-app" route.routeApp_name
                ]
                    |> List.map (\appName -> model.model_config.config_apps |> Dict.get appName |> Maybe.map (\app -> ( appName, app )))
                    |> Maybe.orList
            of
                Just ( appName, app ) ->
                    ( let
                        requestedAppRuntime =
                            case route.routeApp_runRuntime of
                                Just x ->
                                    Just x

                                Nothing ->
                                    app |> listAppRuntimeAvailable |> List.head
                      in
                      case requestedAppRuntime of
                        Nothing ->
                            { model
                                | model_page =
                                    Page_App
                                        { pageApp_route = { route | routeApp_runShown = False }
                                        , pageApp_app = app
                                        , pageApp_runtime = Nothing
                                        }
                                , model_errors =
                                    if route.routeApp_runShown then
                                        [ Error_App (ErrorApp_NoRuntime route.routeApp_name) ]

                                    else
                                        []
                            }

                        Just selectedAppRuntime ->
                            if app |> hasAppRuntime selectedAppRuntime then
                                { model
                                    | model_page =
                                        Page_App
                                            { pageApp_route = route
                                            , pageApp_app = app
                                            , pageApp_runtime = Just selectedAppRuntime
                                            }
                                }

                            else
                                { model
                                    | model_page =
                                        Page_App
                                            { pageApp_route = { route | routeApp_runShown = False }
                                            , pageApp_app = app
                                            , pageApp_runtime = Just selectedAppRuntime
                                            }
                                    , model_errors = [ Error_App (ErrorApp_NoSuchRuntime app.app_name selectedAppRuntime) ]
                                }
                    , Cmd.batch
                        [ let
                            isSameFocus =
                                case model.model_page of
                                    Page_App oldPageApp ->
                                        oldPageApp.pageApp_route.routeApp_focus == route.routeApp_focus

                                    _ ->
                                        False
                          in
                          if isSameFocus then
                            Cmd.none

                          else
                            case route.routeApp_focus of
                                Just focus ->
                                    scrollToAndHighlight (focus |> showRouteAppFocus)

                                Nothing ->
                                    Cmd.none
                        , if route.routeApp_name /= appName then
                            -- Migrate the URL from using an old application name to the latest one.
                            Navigation.replaceUrl Main.Ports.Navigation.navCmd (Route_App { route | routeApp_name = appName } |> routeToAppUrl)

                          else
                            Cmd.none
                        ]
                    )

                Nothing ->
                    ( { model
                        | model_page = defaultPage
                        , model_errors = [ Error_App (ErrorApp_NotFound route.routeApp_name) ]
                      }
                    , Cmd.none
                    )
