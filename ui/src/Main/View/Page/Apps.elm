module Main.View.Page.Apps exposing (..)

import Html exposing (Html, a, div, h5, img, p, text)
import Html.Attributes exposing (attribute, class, href, src, style)
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.List as List
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
    div []
        [ viewPageAppsPagination
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
        , let
            nextPageApps =
                pageApps.pageApps_pagination.pagePagination_list
                    |> List.at pageApps.pageApps_pagination.pagePagination_current
                    |> Maybe.withDefault []
          in
          div [ style "display" "none" ]
            (List.map
                (\app ->
                    (if app.app_hasIcon then
                        img

                     else
                        Html.node "avatar-icon"
                    )
                        ([ attribute "data-display-name" app.app_displayName
                         , attribute "data-app-name" app.app_name
                         ]
                            ++ (if app.app_hasIcon then
                                    [ src (getAppIconPath app.app_name) ]

                                else
                                    []
                               )
                        )
                        []
                )
                nextPageApps
            )
        ]


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
    div
        [ class "card m-item-card shadow-sm p-2 p-sm-3 h-100 d-flex flex-column"
        , attribute "data-testid" "app-result"
        , onClick (Update_Route onClickRoute)
        , style "cursor" "pointer"
        ]
        [ div
            [ class "d-flex flex-column align-items-center w-100"
            ]
            [ (if app.app_hasIcon then
                img

               else
                Html.node "avatar-icon"
              )
                ([ class "item-card-icon mb-2"
                 , attribute "alt" (app.app_displayName ++ " icon")
                 , attribute "data-display-name" app.app_displayName
                 , attribute "data-app-name" app.app_name
                 ]
                    ++ (if app.app_hasIcon then
                            [ src (getAppIconPath app.app_name) ]

                        else
                            []
                       )
                )
                []
            , h5 [ class "mb-1 fw-bold item-card-title text-center text-truncate w-100 px-2" ]
                [ a
                    [ href (onClickRoute |> routeToString)
                    , class "text-decoration-none"
                    , style "color" "inherit"
                    , onClick (Update_Route onClickRoute)
                    , attribute "draggable" "false"
                    ]
                    [ text app.app_displayName ]
                ]
            ]
        , div
            [ class "flex-grow-1 d-flex align-items-center w-100 my-2" ]
            [ p
                [ class "mb-0 text-body-secondary m-item-card-description text-center w-100"
                ]
                [ text app.app_description ]
            ]
        , div
            [ class "d-flex flex-wrap justify-content-center align-items-center gap-1 w-100 mt-auto"
            ]
            (List.concat
                [ if app.app_programs.appPrograms_runtimes.appProgramsRuntimes_program.enable then
                    [ viewRuntimeBadge AppRuntime_Program ]

                  else
                    []
                , if app.app_programs.appPrograms_runtimes.appProgramsRuntimes_shell.enable then
                    [ viewRuntimeBadge AppRuntime_Shell ]

                  else
                    []
                , if app.app_services.appServices_runtimes.appServicesRuntimes_container.enable then
                    [ viewRuntimeBadge AppRuntime_Container ]

                  else
                    []
                , if app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
                    [ viewRuntimeBadge AppRuntime_NixOS ]

                  else
                    []
                ]
            )
        ]
