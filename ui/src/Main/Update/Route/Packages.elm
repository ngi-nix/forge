module Main.Update.Route.Packages exposing (..)

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


updateRoutePackages : RoutePackages -> Updater
updateRoutePackages route =
    getConfig <|
        \model ->
            let
                search =
                    route.routePackages_search |> String.toLower

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
                    getSearchItemsAvailable
                        model.model_page
                        (\page ->
                            case page of
                                Page_Packages pagePackages ->
                                    Just ( pagePackages.pagePackages_route.routePackages_search, pagePackages.pagePackages_pagination.pagePagination_list )

                                _ ->
                                    Nothing
                        )
                        (model.model_config.config_packages |> Dict.values)
                        search

                filteredItems =
                    availableItems
                        |> filterMatches
            in
            { model
                | model_page =
                    Page_Packages
                        { pagePackages_route = route
                        , pagePackages_pagination =
                            defaultPagePagination
                                route.routePackages_pagination
                                filteredItems
                        }
                , model_search = route.routePackages_search
            }
                |> updateFocus
                    showRoutePackagesFocus
                    (case model.model_page of
                        Page_Packages oldPagePackages ->
                            oldPagePackages.pagePackages_route.routePackages_focus

                        _ ->
                            Nothing
                    )
                    route.routePackages_focus
