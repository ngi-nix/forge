module Main.Update exposing (..)

import Browser.Dom as Dom
import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Cmd as Cmd
import Main.Helpers.Nix exposing (..)
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.Clipboard as Clipboard
import Main.Ports.Navigation
import Main.Ports.SmoothScroll exposing (..)
import Main.Update.Config exposing (..)
import Main.Update.Focus exposing (..)
import Main.Update.Route exposing (..)
import Main.Update.Search exposing (..)
import Main.Update.Types exposing (..)
import Navigation
import Task


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
            case event.appUrl |> appUrlToRoute of
                Err err ->
                    ( { model | model_errors = [ Error_Route err ] }
                    , Cmd.none
                    )

                Ok route ->
                    model |> updateRoute route

        Update_Route route ->
            ( model
            , Navigation.pushUrl Main.Ports.Navigation.navCmd (route |> routeToAppUrl)
            )

        Update_RouteWithoutNavigation route ->
            model |> updateRoute route

        Update_RouteWithoutHistory route ->
            let
                ( newModel, routeCmd ) =
                    updateRoute route model

                navCmd =
                    Navigation.replaceUrl Main.Ports.Navigation.navCmd (route |> routeToAppUrl)
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
                model
                    |> update (Update_Search "")
                    |> Cmd.append (Task.attempt Update_FocusResult (Dom.blur "main-search-bar"))

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
