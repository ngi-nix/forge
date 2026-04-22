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
import Main.Update.Config exposing (..)
import Main.Update.Focus exposing (..)
import Main.Update.Route.App exposing (..)
import Main.Update.Route.Apps exposing (..)
import Main.Update.Route.Packages exposing (..)
import Main.Update.Route.Recipe exposing (..)
import Main.Update.Search exposing (..)
import Main.Update.Types exposing (..)


updateRoute : Route -> Updater
updateRoute route =
    case route of
        Route_App routeApp ->
            updateRouteApp routeApp

        Route_Apps routeApps ->
            updateRouteApps routeApps

        Route_Packages routePackages ->
            updateRoutePackages routePackages

        Route_RecipeOptions routeRecipe ->
            updateRouteRecipeOptions routeRecipe
