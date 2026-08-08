module Main.View.Page.Apps exposing (..)

import Html exposing (Html, a, div, h5, img, p, small, span, text)
import Html.Attributes exposing (attribute, class, href, src, style)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Pagination exposing (PaginationVisibility(..), viewPaginationItems, viewPaginationNavigation)


viewPageApps : Model -> PageApps -> Html Update
viewPageApps model pageApps =
    viewPageAppsPagination
        pageApps.pageApps_pagination
        (viewPageAppsApp model pageApps)
        (\modifyRoutePagination ->
            let
                routeApps =
                    pageApps.pageApps_route
            in
            Route_Apps
                { routeApps
                    | routeApps_pagination = routeApps.routeApps_pagination |> modifyRoutePagination
                }
        )


viewPageAppsPagination : PagePagination a -> (a -> Html Update) -> ((RoutePagination -> RoutePagination) -> Route) -> Html Update
viewPageAppsPagination pagePagination viewItem reRoute =
    div []
        [ div [ class "m-item-grid" ] (viewPaginationItems pagePagination viewItem)
        , viewPaginationNavigation PaginationVisibility_HiddenIfSinglePage pagePagination reRoute
        ]


viewPageAppsApp : Model -> PageApps -> App -> Html Update
viewPageAppsApp _ _ app =
    let
        onClickRoute =
            Route_App { defaultRouteApp | routeApp_name = app.app_name }
    in
    a
        [ href (onClickRoute |> routeToString)
        , class "card m-item-card shadow-sm p-2 p-sm-3"
        , style "text-decoration" "none"
        , attribute "data-testid" "app-result"
        , onClick (Update_Route onClickRoute)
        ]
        [ div
            [ class "d-flex flex-column align-items-center w-100"
            ]
            [ img
                [ src (getAppIconPath app.app_name)
                , class "item-card-icon mb-2"
                , attribute "loading" "lazy"
                , attribute "alt" (app.app_displayName ++ " icon")
                ]
                []
            , h5 [ class "mb-1 fw-bold item-card-title text-center" ] [ text app.app_displayName ]
            , p
                [ class "mb-2 text-body-secondary m-item-card-description text-center"
                ]
                [ text app.app_description ]
            ]
        , div
            [ class "d-none d-sm-flex flex-wrap justify-content-center align-items-center gap-1 w-100 mt-auto"
            ]
            (List.concat
                [ if app.app_programs.appPrograms_runtimes.appProgramsRuntimes_program.enable then
                    [ span [ class "badge rounded-pill bg-primary-subtle text-primary-emphasis border border-primary-subtle" ] [ text "program" ] ]

                  else
                    []
                , if app.app_programs.appPrograms_runtimes.appProgramsRuntimes_shell.enable then
                    [ span [ class "badge rounded-pill bg-primary-subtle text-primary-emphasis border border-primary-subtle" ] [ text "shell" ] ]

                  else
                    []
                , if app.app_services.appServices_runtimes.appServicesRuntimes_container.enable then
                    [ span [ class "badge rounded-pill bg-primary-subtle text-primary-emphasis border border-primary-subtle" ] [ text "container" ] ]

                  else
                    []
                , if app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
                    [ span [ class "badge rounded-pill bg-primary-subtle text-primary-emphasis border border-primary-subtle" ] [ text "nixos" ] ]

                  else
                    []
                ]
            )
        ]
