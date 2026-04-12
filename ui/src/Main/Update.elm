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
import Main.Model.Page exposing (..)
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
    | Update_Search Search
    | Update_NoOp


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

        Update_Search search ->
            if
                -- Delay the search on `Page`s not already displaying search results
                -- when the search was empty (resp. becomes empty),
                -- which is triggered by `Update_Search input.key` (resp. `Update_Search ""`)
                -- in the `Update_AmbientKeyPress` case.
                not (isPageSearch model.model_page)
                    && (model.model_search == "" || search == "")
            then
                ( { model | model_search = search }
                , Cmd.none
                )

            else
                -- Otherwise always show search results immediately.
                { model | model_search = search }
                    |> update (Update_Route (routeSearch model search))

        Update_AmbientKeyPress input ->
            if input.key == "Escape" then
                model |> update (Update_Search "")

            else if not input.focusedTyping && not input.hasModifier then
                if input.key == "/" then
                    ( model
                    , Task.attempt Update_FocusResult (Dom.focus "main-search-bar")
                    )

                else if (String.length input.key == 1) && (input.key |> String.all Char.isAlphaNum) then
                    { model | model_search = "" }
                        |> update (Update_Search input.key)
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
                            { recipeOptions_available = options
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
                                | model_page = defaultPage
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
                            Just focus ->
                                scrollToAndHighlight (focus |> showRouteAppFocus)

                            Nothing ->
                                Cmd.none
                    )

        Route_Apps routeApps ->
            updateConfig <|
                \model ->
                    ( { model
                        | model_page = Page_Apps { pageApps_route = routeApps }
                        , model_search = routeApps.routeApps_search
                      }
                    , Cmd.none
                    )

        Route_Packages routePackages ->
            updateConfig <|
                \model ->
                    let
                        search =
                            routePackages.routePackages_search |> String.toLower

                        filterMatches =
                            List.filter
                                (\package ->
                                    let
                                        -- Case Insensitive search
                                        package_name =
                                            String.toLower package.package_name

                                        package_description =
                                            String.toLower package.package_description

                                        name_matches =
                                            String.contains search package_name

                                        desc_matches =
                                            String.contains search package_description
                                    in
                                    name_matches || desc_matches
                                )

                        availableItems =
                            case model.model_page of
                                Page_Packages pagePackages ->
                                    if String.contains pagePackages.pagePackages_route.routePackages_search search then
                                        pagePackages.pagePackages_pagination.pagePagination_list
                                            |> List.concat

                                    else
                                        model.model_config.config_packages
                                            |> Dict.values

                                _ ->
                                    model.model_config.config_packages
                                        |> Dict.values

                        filteredItems =
                            availableItems
                                |> filterMatches
                    in
                    { model
                        | model_page =
                            Page_Packages
                                { pagePackages_route = routePackages
                                , pagePackages_pagination =
                                    defaultPagePagination
                                        routePackages.routePackages_pagination
                                        filteredItems
                                }
                        , model_search = routePackages.routePackages_search
                    }
                        |> updateFocus
                            showRoutePackagesFocus
                            (case model.model_page of
                                Page_Packages oldPagePackages ->
                                    oldPagePackages.pagePackages_route.routePackages_focus

                                _ ->
                                    Nothing
                            )
                            routePackages.routePackages_focus

        Route_RecipeOptions routeRecipe ->
            updateConfig <|
                updateRecipeOptions <|
                    \model ->
                        let
                            search =
                                routeRecipe.routeRecipeOptions_search |> String.toLower

                            filterMatches =
                                List.filter
                                    (\( name, option ) ->
                                        let
                                            -- Case Insensitive search
                                            option_name =
                                                String.toLower name

                                            option_description =
                                                String.toLower option.nixModuleOption_description

                                            name_matches =
                                                String.contains search option_name

                                            desc_matches =
                                                String.contains search option_description
                                        in
                                        name_matches || desc_matches
                                    )

                            availableItems =
                                case model.model_page of
                                    Page_RecipeOptions pageRecipe ->
                                        if String.contains pageRecipe.pageRecipeOptions_route.routeRecipeOptions_search search then
                                            pageRecipe.pageRecipeOptions_pagination.pagePagination_list
                                                |> List.concat

                                        else
                                            model.model_RecipeOptions.recipeOptions_available
                                                |> Dict.toList

                                    _ ->
                                        model.model_RecipeOptions.recipeOptions_available
                                            |> Dict.toList

                            filteredItems =
                                availableItems
                                    |> filterMatches
                        in
                        { model
                            | model_page =
                                Page_RecipeOptions
                                    { pageRecipeOptions_route = routeRecipe
                                    , pageRecipeOptions_pagination =
                                        defaultPagePagination
                                            routeRecipe.routeRecipeOptions_pagination
                                            filteredItems
                                    }
                            , model_search = routeRecipe.routeRecipeOptions_search
                        }
                            |> updateFocus
                                showRouteRecipeOptionsFocus
                                (case model.model_page of
                                    Page_RecipeOptions oldPageRecipe ->
                                        oldPageRecipe.pageRecipeOptions_route.routeRecipeOptions_focus

                                    _ ->
                                        Nothing
                                )
                                routeRecipe.routeRecipeOptions_focus


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


routeSearch : Model -> Search -> Route
routeSearch model search =
    case model.model_page of
        Page_App pageApp ->
            Route_Apps { routeApps_search = search }

        Page_Apps pageApps ->
            let
                routeApps =
                    pageApps.pageApps_route
            in
            Route_Apps { routeApps | routeApps_search = search }

        Page_Packages pagePackages ->
            let
                routePackages =
                    pagePackages.pagePackages_route

                routePagination =
                    routePackages.routePackages_pagination
            in
            Route_Packages
                { routePackages
                    | routePackages_search = search
                    , routePackages_pagination = { routePagination | routePagination_current = Nothing }
                }

        Page_RecipeOptions pageRecipeOptions ->
            let
                routeRecipeOptions =
                    pageRecipeOptions.pageRecipeOptions_route

                routePagination =
                    routeRecipeOptions.routeRecipeOptions_pagination
            in
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_search = search
                    , routeRecipeOptions_pagination = { routePagination | routePagination_current = Nothing }
                }


updateFocus : (a -> String) -> Maybe a -> Maybe a -> Model -> ( Model, Cmd Update )
updateFocus showFocus prevFocus nextFocus model =
    ( model
    , case nextFocus of
        Just focus ->
            if Just focus /= prevFocus then
                scrollToAndHighlight (focus |> showFocus)

            else
                Cmd.none

        Nothing ->
            Cmd.none
    )


{-| `updateRecipeOptions up` populates `model.model_recipe.modelRecipeOptions_available` if empty, then runs `up`.
`up` is thus always run, and only after `model.model_recipe.modelRecipeOptions_available` has been loaded.
-}
updateRecipeOptions : Updater -> Updater
updateRecipeOptions up model =
    if Dict.isEmpty model.model_RecipeOptions.recipeOptions_available then
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
