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
        , class "card m-item-card shadow-sm p-3"
        , style "text-decoration" "none"
        , attribute "data-testid" "app-result"
        , onClick (Update_Route onClickRoute)
        ]
        [ div
            [ class "w-100"
            , style "display" "flex"
            , style "align-items" "center"
            , style "gap" "12px"
            ]
            [ img
                [ src (getAppIconPath app.app_name)
                , class "item-card-icon"
                , attribute "loading" "lazy"
                , attribute "alt" (app.app_displayName ++ " icon")
                ]
                []
            , h5 [ class "mb-10" ] [ text app.app_displayName ]
            ]
        , p
            [ class "mb-1"
            ]
            [ text app.app_description ]
        , p
            [ class "mb-1"
            ]
            [ small []
                (List.concat
                    [ if app.app_programs.appPrograms_runtimes.appProgramsRuntimes_shell.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "shell" ] ]

                      else
                        []
                    , if app.app_services.appServices_runtimes.appServicesRuntimes_container.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "container" ] ]

                      else
                        []
                    , if app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "nixos" ] ]

                      else
                        []
                    ]
                )
            ]
        ]
