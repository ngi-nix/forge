module Main.Update.Search exposing (..)

import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.SmoothScroll exposing (..)
import Main.Update.Types exposing (..)


routeSearch : Model -> Search -> Route
routeSearch model search =
    case model.model_page of
        Page_App _ ->
            Route_Apps { defaultRouteApps | routeApps_search = search }

        Page_Apps pageApps ->
            let
                routeApps =
                    pageApps.pageApps_route

                routePagination =
                    routeApps.routeApps_pagination
            in
            Route_Apps
                { routeApps
                    | routeApps_search = search
                    , routeApps_pagination = { routePagination | routePagination_current = Nothing }
                }

        Page_Pkgs pagePkgs ->
            let
                routePkgs =
                    pagePkgs.pagePkgs_route

                routePagination =
                    routePkgs.routePkgs_pagination
            in
            Route_Pkgs
                { routePkgs
                    | routePkgs_search = search
                    , routePkgs_pagination = { routePagination | routePagination_current = Nothing }
                }

        Page_RecipeOptions pageRecipeOptions ->
            let
                route =
                    pageRecipeOptions.pageRecipeOptions_route

                routePagination =
                    route.routeRecipeOptions_pagination
            in
            Route_RecipeOptions
                { route
                    | routeRecipeOptions_searchPattern = search
                    , routeRecipeOptions_pagination = { routePagination | routePagination_current = Nothing }
                }


{-| Optimization to avoid re-filtering the entire list when the new search contains the previous search.
-}
getSearchItemsAvailable : Page -> (Page -> Maybe ( String, List (List a) )) -> List a -> String -> List a
getSearchItemsAvailable model_page getPrevious allItems newSearch =
    case getPrevious model_page of
        Just ( previousSearch, previousItems ) ->
            if not (String.isEmpty previousSearch) && String.contains previousSearch newSearch then
                previousItems |> List.concat

            else
                allItems

        Nothing ->
            allItems
