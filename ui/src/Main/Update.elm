module Main.Update exposing (..)

import Browser.Dom as Dom
import Dict
import Http
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Error exposing (..)
import Main.Helpers.Cmd as Cmd
import Main.Helpers.List as List
import Main.Helpers.Nix exposing (..)
import Main.Model exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Ports.Clipboard as Clipboard
import Main.Ports.Navigation
import Main.Ports.SmoothScroll exposing (..)
import Main.Route as Route exposing (..)
import Navigation
import Task


type alias Updater =
    Model -> ( Model, Cmd Update )


type Update
    = -- `Update_Chain us` left-folds `Update` in `us` on the `Model`.
      Update_Chain (List Update)
    | Update_CopyToClipboard String
    | Update_Config (Result Http.Error Config)
    | -- `Update_RecipeOptions res` loads the `res` of `updateRecipeOptions` into `model_RecipeOptions`.
      Update_RecipeOptions (Result Http.Error NixModuleOptions)
    | Update_Navigation Navigation.Event
    | Update_Route Route
    | Update_RouteWithoutNavigation Route
    | Update_RouteWithoutHistory Route
    | -- `Update_Updater up` simply applies `up` to the `Model`.
      -- Useful in a `Update_Chain` to defer `up` after some other updates.
      Update_Updater Updater
    | Update_ToggleNavBar
    | Update_CycleTheme
    | Update_Focus String
    | Update_SetPreferences Preferences
    | Update_FocusResult (Result Dom.Error ())
    | Update_AmbientKeyPress AmbientKeyState
    | Update_SearchInput UpdateSearchInput
    | Update_NoOp


type UpdateSearchInput
    = -- Like `UpdateSearchInput_Set ""` but without actually changing the `model_page` and URL,
      -- in order to let the Escape key clear the search and remain on the same `model_page`.
      UpdateSearchInput_PreClear
    | -- Like `UpdateSearchInput_Set s` but without actually changing the `model_page` and URL,
      -- in order to let the Escape key clear the search and remain on the same `model_page`.
      UpdateSearchInput_PreSet String
    | -- Set the search pattern, and update the `model_page` and URL
      -- according to the current `model_page`.
      UpdateSearchInput_Set String


type alias AmbientKeyState =
    { key : String
    , focusedTyping : Bool
    , hasModifier : Bool
    }


update : Update -> Updater
update upd modelInit =
    let
        model =
            { modelInit | model_errors = [] }
    in
    case upd of
        Update_Chain ups ->
            let
                chain up ( model1, cmds1 ) =
                    let
                        ( model2, cmds2 ) =
                            update up model1
                    in
                    ( { model2 | model_errors = model1.model_errors ++ model2.model_errors }
                    , Cmd.batch [ cmds1, cmds2 ]
                    )
            in
            ups |> List.foldl chain ( { model | model_errors = [] }, Cmd.none )

        Update_Navigation event ->
            case event.appUrl |> Route.fromAppUrl of
                Err err ->
                    ( { model | model_errors = [ Error_Route err ] }
                    , Cmd.none
                    )

                Ok route ->
                    model |> updateRoute route

        Update_Route route ->
            ( model
            , Navigation.pushUrl Main.Ports.Navigation.navCmd (route |> Route.toAppUrl)
            )

        Update_RouteWithoutNavigation route ->
            model |> updateRoute route

        Update_RouteWithoutHistory route ->
            let
                ( newModel, routeCmd ) =
                    updateRoute route model

                navCmd =
                    Navigation.replaceUrl Main.Ports.Navigation.navCmd (route |> Route.toAppUrl)
            in
            ( newModel
            , Cmd.batch [ routeCmd, navCmd ]
            )

        Update_CopyToClipboard code ->
            ( model
            , Clipboard.copyToClipboard code
            )

        Update_SetPreferences prefs ->
            ( { model | model_preferences = prefs }
            , setPreferences prefs
            )

        Update_CycleTheme ->
            let
                preferences =
                    model.model_preferences
            in
            model
                |> update
                    (Update_SetPreferences
                        { preferences
                            | preferences_theme =
                                cyclePreferencesTheme model.model_preferences.preferences_theme
                        }
                    )

        Update_ToggleNavBar ->
            ( { model | model_navbarExpanded = not model.model_navbarExpanded }, Cmd.none )

        Update_SearchInput usi ->
            case usi of
                UpdateSearchInput_PreClear ->
                    model
                        |> updateRoute
                            (case model.model_page of
                                Page_RecipeOptions pageRecipeOptions ->
                                    let
                                        routeRecipeOptions =
                                            pageRecipeOptions.pageRecipeOptions_route
                                    in
                                    Route_RecipeOptions
                                        { routeRecipeOptions
                                            | routeRecipeOptions_pattern = Nothing
                                            , routeRecipeOptions_page = Nothing
                                        }

                                _ ->
                                    Route_Search { routeSearch_pattern = "" }
                            )
                        |> (\( m, c ) -> ( { m | model_page = model.model_page }, c ))
                        |> Cmd.append (Task.attempt Update_FocusResult (Dom.blur "main-search-bar"))

                UpdateSearchInput_PreSet search ->
                    model
                        |> updateRoute
                            (case model.model_page of
                                Page_RecipeOptions pageRecipeOptions ->
                                    let
                                        routeRecipeOptions =
                                            pageRecipeOptions.pageRecipeOptions_route
                                    in
                                    Route_RecipeOptions
                                        { routeRecipeOptions
                                            | routeRecipeOptions_pattern = Just search
                                            , routeRecipeOptions_page = Nothing
                                        }

                                _ ->
                                    Route_Search { routeSearch_pattern = search }
                            )
                        |> (\( m, c ) -> ( { m | model_page = model.model_page }, c ))

                UpdateSearchInput_Set search ->
                    model
                        |> update
                            (Update_Route
                                (case model.model_page of
                                    Page_RecipeOptions pageRecipeOptions ->
                                        let
                                            routeRecipeOptions =
                                                pageRecipeOptions.pageRecipeOptions_route
                                        in
                                        Route_RecipeOptions
                                            { routeRecipeOptions
                                                | routeRecipeOptions_pattern = Just search
                                                , routeRecipeOptions_page = Nothing
                                            }

                                    _ ->
                                        Route_Search { routeSearch_pattern = search }
                                )
                            )

        Update_AmbientKeyPress input ->
            if input.key == "Escape" then
                model
                    |> update (Update_SearchInput UpdateSearchInput_PreClear)

            else if not input.focusedTyping && not input.hasModifier then
                if input.key == "/" then
                    ( model
                    , Task.attempt Update_FocusResult (Dom.focus "main-search-bar")
                    )

                else if (String.length input.key == 1) && (input.key |> String.all Char.isAlphaNum) then
                    model
                        |> update (Update_SearchInput (UpdateSearchInput_PreSet input.key))
                        |> Cmd.append (Task.attempt Update_FocusResult (Dom.focus "main-search-bar"))

                else
                    ( model, Cmd.none )

            else
                ( model, Cmd.none )

        Update_Focus id ->
            ( model
            , Task.attempt Update_FocusResult (Dom.focus id)
            )

        Update_FocusResult _ ->
            -- Dom.focus and Dom.blur return a Result.
            -- We don't need to do anything if they succeed or fail.
            ( model, Cmd.none )

        Update_Config res ->
            case res of
                Ok config ->
                    ( { model | model_config = config }
                    , Cmd.none
                    )

                Err err ->
                    ( { model | model_errors = [ Error_Http err ] }
                    , Cmd.none
                    )

        Update_RecipeOptions res ->
            case res of
                Ok options ->
                    ( { model
                        | model_RecipeOptions =
                            { modelRecipeOptions_available = options
                            , modelRecipeOptions_filtered = options |> Dict.toList
                            }
                      }
                    , Cmd.none
                    )

                Err err ->
                    ( { model | model_errors = [ Error_Http err ] }
                    , Cmd.none
                    )

        Update_NoOp ->
            ( model, Cmd.none )

        Update_Updater up ->
            model |> up


updateRoute : Route -> Updater
updateRoute route =
    case route of
        Route_Search routeSearch ->
            updateConfig <|
                \model ->
                    ( { model
                        | model_page = Page_Search
                        , model_search = routeSearch.routeSearch_pattern
                      }
                    , Cmd.none
                    )

        Route_App routeApp ->
            updateConfig <|
                \model ->
                    ( case model.model_config.config_apps |> Dict.get routeApp.routeApp_name of
                        Just app ->
                            let
                                requestedAppRuntime =
                                    case routeApp.routeApp_runRuntime of
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
                                                { pageApp_route = { routeApp | routeApp_runShown = False }
                                                , pageApp_app = app
                                                , pageApp_runtime = Nothing
                                                }
                                        , model_errors =
                                            if routeApp.routeApp_runShown then
                                                [ Error_App (ErrorApp_NoRuntime routeApp.routeApp_name) ]

                                            else
                                                []
                                    }

                                Just selectedAppRuntime ->
                                    if app |> hasAppRuntime selectedAppRuntime then
                                        { model
                                            | model_page =
                                                Page_App
                                                    { pageApp_route = routeApp
                                                    , pageApp_app = app
                                                    , pageApp_runtime = Just selectedAppRuntime
                                                    }
                                        }

                                    else
                                        { model
                                            | model_page =
                                                Page_App
                                                    { pageApp_route = { routeApp | routeApp_runShown = False }
                                                    , pageApp_app = app
                                                    , pageApp_runtime = Just selectedAppRuntime
                                                    }
                                            , model_errors = [ Error_App (ErrorApp_NoSuchRuntime app.app_name selectedAppRuntime) ]
                                        }

                        Nothing ->
                            { model
                                | model_page = Page_Search
                                , model_errors = [ Error_App (ErrorApp_NotFound routeApp.routeApp_name) ]
                            }
                    , let
                        isSameFocus =
                            case model.model_page of
                                Page_App oldPageApp ->
                                    oldPageApp.pageApp_route.routeApp_focus == routeApp.routeApp_focus

                                _ ->
                                    False
                      in
                      if isSameFocus then
                        Cmd.none

                      else
                        case routeApp.routeApp_focus of
                            Just targetId ->
                                scrollToAndHighlight (targetId |> showRouteAppFocus)

                            Nothing ->
                                Cmd.none
                    )

        Route_RecipeOptions routeRecipe ->
            updateConfig <|
                updateRecipeOptions <|
                    \model ->
                        let
                            recipeOptions =
                                model.model_RecipeOptions

                            search =
                                routeRecipe.routeRecipeOptions_pattern |> Maybe.withDefault ""

                            filtered =
                                recipeOptions.modelRecipeOptions_available
                                    |> Dict.filter (\name _ -> String.contains (search |> String.toLower) (name |> String.toLower))
                                    |> Dict.toList

                            maxResultsPerPage =
                                routeRecipe.routeRecipeOptions_MaxResultsPerPage
                                    |> Maybe.withDefault 10

                            pageRecipe =
                                { pageRecipeOptions_route = routeRecipe
                                , pageRecipeOptions_page =
                                    routeRecipe.routeRecipeOptions_page
                                        |> Maybe.withDefault 1
                                , pageRecipeOptions_MaxResultsPerPage = maxResultsPerPage
                                , pageRecipeOptions_LastPage =
                                    filtered
                                        |> List.length
                                        |> (\x -> (toFloat x / toFloat maxResultsPerPage) |> ceiling)
                                        |> max 1
                                }
                        in
                        ( { model
                            | model_page = Page_RecipeOptions pageRecipe
                            , model_search = search
                            , model_RecipeOptions =
                                { recipeOptions
                                    | modelRecipeOptions_filtered =
                                        filtered
                                            |> List.chunksOf pageRecipe.pageRecipeOptions_MaxResultsPerPage
                                            |> List.at (pageRecipe.pageRecipeOptions_page - 1)
                                            |> Maybe.withDefault []
                                }
                          }
                        , let
                            isSameFocus =
                                case model.model_page of
                                    Page_RecipeOptions oldRecipePage ->
                                        oldRecipePage.pageRecipeOptions_route.routeRecipeOptions_focus == routeRecipe.routeRecipeOptions_focus

                                    _ ->
                                        False
                          in
                          if isSameFocus then
                            Cmd.none

                          else
                            case routeRecipe.routeRecipeOptions_focus of
                                Just targetId ->
                                    scrollToAndHighlight (targetId |> showRouteRecipeOptionsFocus)

                                Nothing ->
                                    Cmd.none
                        )


{-| `updateConfig up` populates `model_config` if empty, then runs `up`.
`up` is thus always run, and only after `model_config` has been loaded.
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
                    decodeConfig
            }
        )

    else
        model |> up


{-| `updateRecipeOptions up` populates `model.model_recipe.modelRecipeOptions_available` if empty, then runs `up`.
`up` is thus always run, and only after `model.model_recipe.modelRecipeOptions_available` has been loaded.
-}
updateRecipeOptions : Updater -> Updater
updateRecipeOptions up model =
    if Dict.isEmpty model.model_RecipeOptions.modelRecipeOptions_available then
        ( model
        , Http.get
            { url = "forge-options.json"
            , expect =
                Http.expectJson
                    (\res ->
                        Update_Chain
                            [ Update_RecipeOptions res
                            , Update_Updater up
                            ]
                    )
                    decodeNixModuleOptions
            }
        )

    else
        model |> up
