module Main.Update.Route exposing (..)

import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.SmoothScroll exposing (..)
import Main.Ports.Title exposing (setTitle)
import Main.Update.Config exposing (..)
import Main.Update.Focus exposing (..)
import Main.Update.Route.App exposing (..)
import Main.Update.Route.Apps exposing (..)
import Main.Update.Route.Pkgs exposing (..)
import Main.Update.Route.Recipe exposing (..)
import Main.Update.Search exposing (..)
import Main.Update.Types exposing (..)


updateRoute : Route -> Updater
updateRoute route model =
    let
        ( newModel, routeCmd ) =
            case route of
                Route_App routeApp ->
                    updateRouteApp routeApp model

                Route_Apps routeApps ->
                    updateRouteApps routeApps model

                Route_Pkgs routePkgs ->
                    updateRoutePkgs routePkgs model

                Route_RecipeOptions routeRecipe ->
                    updateRouteRecipeOptions routeRecipe model

        titleCmd =
            setTitle (pageTitle newModel.model_page)
    in
    ( newModel
    , Cmd.batch [ routeCmd, titleCmd ]
    )


{-| Derive the browser tab title from the current `Page`.
-}
pageTitle : Page -> String
pageTitle page =
    let
        suffix =
            "NGI Forge"
    in
    case page of
        Page_App pageApp ->
            pageApp.pageApp_app.app_displayName ++ " — " ++ suffix

        Page_Apps _ ->
            "Apps — " ++ suffix

        Page_Pkgs _ ->
            "Pkgs — " ++ suffix

        Page_RecipeOptions _ ->
            "Recipe Options — " ++ suffix
