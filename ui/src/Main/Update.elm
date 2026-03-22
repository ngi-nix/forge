module Main.Update exposing (..)

import Browser.Dom as Dom
import Dict
import Http
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Error exposing (..)
import Main.Model exposing (..)
import Main.Ports.Clipboard as Clipboard
import Main.Ports.Navigation
import Main.Ports.ThemeSwitch as ThemeSwitch
import Main.Route as Route exposing (..)
import Main.Theme exposing (cycleTheme, themeToString)
import Navigation
import Task


type alias Updater =
    Model -> ( Model, Cmd Update )


type Update
    = Update_Chain (List Update)
    | Update_CopyToClipboard String
    | Update_Config (Result Http.Error Config)
    | Update_Navigation Navigation.Event
    | Update_Route Route
    | Update_Updater Updater
    | Update_CycleTheme
    | Update_FocusResult (Result Dom.Error ())
    | Update_AmbientKeyPress AmbientKeyState
    | Update_SearchInput String
    | Update_CancelSearch
    | Update_NoOp


type alias AmbientKeyState =
    { key : String
    , focusedTyping : Bool
    , hasModifier : Bool
    }


update : Update -> Updater
update upd model =
    case upd of
        Update_Chain ups ->
            let
                chain msg1 ( model1, cmds1 ) =
                    let
                        ( model2, cmds2 ) =
                            update msg1 model1
                    in
                    ( model2, Cmd.batch [ cmds1, cmds2 ] )
            in
            ups |> List.foldl chain ( model, Cmd.none )

        Update_Navigation event ->
            case event.appUrl |> Route.fromAppUrl of
                Err err ->
                    ( { model | model_errors = model.model_errors ++ [ Error_Route err ] }
                    , Cmd.none
                    )

                Ok route ->
                    model |> updateConfig (updateRoute route)

        Update_Route route ->
            ( model
            , Navigation.pushUrl Main.Ports.Navigation.navCmd (route |> Route.toAppUrl)
            )

        Update_CopyToClipboard code ->
            ( model
            , Clipboard.copyToClipboard code
            )

        Update_CycleTheme ->
            let
                nextTheme =
                    cycleTheme model.model_theme
            in
            ( { model | model_theme = nextTheme }
            , ThemeSwitch.saveTheme (themeToString nextTheme)
            )

        Update_CancelSearch ->
            ( { model | model_search = "" }
            , Task.attempt Update_FocusResult (Dom.blur "main-search-bar")
            )

        Update_SearchInput search ->
            ( { model | model_search = search }
            , Navigation.pushUrl Main.Ports.Navigation.navCmd (Route_Search { routeSearch_pattern = search } |> Route.toAppUrl)
            )

        Update_AmbientKeyPress input ->
            if input.key == "Escape" then
                ( { model | model_search = "" }
                , Task.attempt Update_FocusResult (Dom.blur "main-search-bar")
                )

            else if not input.focusedTyping && not input.hasModifier then
                if input.key == "/" then
                    ( model
                    , Task.attempt Update_FocusResult (Dom.focus "main-search-bar")
                    )

                else if (String.length input.key == 1) && (String.toList input.key |> List.all Char.isAlphaNum) then
                    ( { model | model_search = input.key }
                    , Task.attempt Update_FocusResult (Dom.focus "main-search-bar")
                    )

                else
                    ( model, Cmd.none )

            else
                ( model, Cmd.none )

        Update_FocusResult _ ->
            -- Dom.focus and Dom.blur return a Result.
            -- We don't need to do anything if they succeed or fail.
            ( model, Cmd.none )

        Update_Config res ->
            case res of
                Ok config ->
                    ( { model | model_config = { config | config_apps = config.config_apps } }
                    , Cmd.none
                    )

                Err err ->
                    ( { model | model_errors = model.model_errors ++ [ Error_Http err ] }
                    , Cmd.none
                    )

        Update_NoOp ->
            ( model, Cmd.none )

        Update_Updater up ->
            model |> up


updateRoute : Route -> Updater
updateRoute route model =
    case route of
        Route_Search routeSearch ->
            ( { model
                | model_page = Page_Search
                , model_search = routeSearch.routeSearch_pattern
              }
            , Cmd.none
            )

        Route_App routeApp ->
            ( case model.model_config.config_apps |> Dict.get routeApp.routeApp_name of
                Just app ->
                    case routeApp.routeApp_runOutput of
                        Nothing ->
                            { model
                                | model_page =
                                    Page_App
                                        { pageApp_route =
                                            { routeApp
                                                | routeApp_runOutput =
                                                    [ if app.app_programs.enable then
                                                        [ AppOutput_Shell ]

                                                      else
                                                        []
                                                    , if app.app_container.enable then
                                                        [ AppOutput_Container ]

                                                      else
                                                        []
                                                    , if app.app_vm.enable then
                                                        [ AppOutput_VM ]

                                                      else
                                                        []
                                                    ]
                                                        |> List.concat
                                                        |> List.head
                                            }
                                        , pageApp_app = app
                                        }
                            }

                        Just output ->
                            let
                                appHasRequestedOutput =
                                    case output of
                                        AppOutput_Shell ->
                                            app.app_programs.enable

                                        AppOutput_Container ->
                                            app.app_container.enable

                                        AppOutput_VM ->
                                            app.app_vm.enable
                            in
                            if appHasRequestedOutput then
                                { model
                                    | model_page =
                                        Page_App
                                            { pageApp_route = routeApp
                                            , pageApp_app = app
                                            }
                                }

                            else
                                { model
                                    | model_page =
                                        Page_App
                                            { pageApp_route = routeApp
                                            , pageApp_app = app
                                            }
                                    , model_errors = model.model_errors ++ [ Error_App (ErrorApp_NoSuchOutput output) ]
                                }

                Nothing ->
                    { model
                        | model_page = Page_Search
                        , model_errors = model.model_errors ++ [ Error_App (ErrorApp_NotFound routeApp.routeApp_name) ]
                    }
            , Cmd.none
            )


{-| `updateConfig up` populate `model_config` if empty, then run `up`.
`up` is thus always run after `model_config` has been updated.
-}
updateConfig : Updater -> Updater
updateConfig up model =
    if Dict.isEmpty model.model_config.config_apps then
        ( model
        , Http.get
            { url = "forge-config.json"
            , expect =
                Http.expectJson
                    (\res ->
                        Update_Chain
                            [ Update_Config res
                            , Update_Updater up
                            ]
                    )
                    Main.Config.decodeConfig
            }
        )

    else
        model |> up
