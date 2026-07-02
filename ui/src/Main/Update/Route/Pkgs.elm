module Main.Update.Route.Pkgs exposing (..)

import Dict
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
import Main.Update.Config exposing (..)
import Main.Update.Focus exposing (..)
import Main.Update.Route.Recipe exposing (..)
import Main.Update.Search exposing (..)
import Main.Update.Types exposing (..)


updateRoutePkgs : RoutePkgs -> Updater
updateRoutePkgs route =
    getConfig <|
        \model ->
            let
                search =
                    route.routePkgs_search |> String.toLower

                filterMatches =
                    List.filter
                        (\pkg ->
                            let
                                -- Case Insensitive search
                                pkg_pname =
                                    String.toLower pkg.pkg_pname

                                pkg_description =
                                    String.toLower pkg.pkg_description

                                name_matches =
                                    String.contains search pkg_pname

                                desc_matches =
                                    String.contains search pkg_description
                            in
                            name_matches || desc_matches
                        )

                availableItems =
                    getSearchItemsAvailable
                        model.model_page
                        (\page ->
                            case page of
                                Page_Pkgs pagePkgs ->
                                    Just ( pagePkgs.pagePkgs_route.routePkgs_search, pagePkgs.pagePkgs_pagination.pagePagination_list )

                                _ ->
                                    Nothing
                        )
                        (model.model_config.config_pkgs |> Dict.values)
                        search

                filteredItems =
                    availableItems
                        |> filterMatches
            in
            { model
                | model_page =
                    Page_Pkgs
                        { pagePkgs_route = route
                        , pagePkgs_pagination =
                            defaultPagePagination
                                route.routePkgs_pagination
                                filteredItems
                        }
                , model_search = route.routePkgs_search
            }
                |> updateFocus
                    showRoutePkgsFocus
                    (case model.model_page of
                        Page_Pkgs oldPagePkgs ->
                            oldPagePkgs.pagePkgs_route.routePkgs_focus

                        _ ->
                            Nothing
                    )
                    route.routePkgs_focus
