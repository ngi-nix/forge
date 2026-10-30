module Main.Update.Route.Apps exposing (..)

import Dict
import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Cmd as Cmd
import Main.Helpers.Nix exposing (..)
import Main.Helpers.String
import Main.Model exposing (..)
import Main.Model.Error exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Ports.SmoothScroll exposing (..)
import Main.Update.Config exposing (..)
import Main.Update.Focus exposing (..)
import Main.Update.Route.Recipe exposing (..)
import Main.Update.Search exposing (..)
import Main.Update.Types exposing (..)
import Random


updateRouteApps : RouteApps -> Updater
updateRouteApps route =
    getConfig <|
        \model ->
            ( let
                search =
                    route.routeApps_search |> String.toLower

                filterMatches =
                    List.filter
                        (\app ->
                            let
                                -- Case Insensitive search
                                app_name =
                                    String.toLower app.app_name

                                app_description =
                                    String.toLower app.app_description

                                name_matches =
                                    String.contains search app_name

                                desc_matches =
                                    String.contains search app_description

                                category_matches =
                                    case route.routeApps_category of
                                        Nothing ->
                                            True

                                        Just category ->
                                            List.member category app.app_categories
                            in
                            (name_matches || desc_matches) && category_matches
                        )

                availableItems =
                    getSearchItemsAvailable
                        model.model_page
                        (\page ->
                            case page of
                                Page_Apps pageApps ->
                                    Just ( pageApps.pageApps_route.routeApps_search, pageApps.pageApps_pagination.pagePagination_list )

                                _ ->
                                    Nothing
                        )
                        (model.model_config.config_apps
                            |> Dict.values
                        )
                        search

                sortApps =
                    \apps ->
                        case model.model_preferences.preferences_sort of
                            PreferencesSort_Alphabetical ->
                                List.sortWith
                                    (\appA appB ->
                                        compare (String.toLower appA.app_displayName) (String.toLower appB.app_displayName)
                                    )
                                    apps

                            PreferencesSort_Random ->
                                let
                                    initialSeed =
                                        Random.initialSeed model.model_ephemeralSeed

                                    generator =
                                        Random.list (List.length apps) (Random.float 0 1)

                                    ( randomFloats, _ ) =
                                        Random.step generator initialSeed
                                in
                                List.map2 Tuple.pair randomFloats apps
                                    |> List.sortBy Tuple.first
                                    |> List.map Tuple.second

                filteredItems =
                    availableItems
                        |> filterMatches
                        |> sortApps
              in
              { model
                | model_page =
                    Page_Apps
                        { pageApps_route = route
                        , pageApps_pagination =
                            defaultPagePagination
                                route.routeApps_pagination
                                filteredItems
                        }
                , model_search = route.routeApps_search
              }
            , Cmd.none
            )
