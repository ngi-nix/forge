module Main.View.Page.Apps exposing (..)

import Dict
import Html exposing (Html, a, div, h5, img, p, small, span, text)
import Html.Attributes exposing (attribute, class, href, src, style, title)
import Html.Events exposing (custom, preventDefaultOn, stopPropagationOn)
import Json.Decode as Decode
import List.Extra
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
    div [ class "row" ]
        [ div [ class "col-md-3 mb-3" ]
            [ h5 [ class "mb-3" ] [ text "Categories" ]
            , viewCategoryFilters model pageApps
            ]
        , div [ class "col-md-9" ]
            [ viewSortDropdown model pageApps
            , viewPageAppsPagination
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
            ]
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
        [ div [ class "row row-cols-1 row-cols-sm-2 row-cols-lg-3 row-cols-xl-4 g-3 mb-4" ]
            (viewPaginationItems pagePagination viewItem
                |> List.map (\item -> div [ class "col" ] [ item ])
            )
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

                    -- FIX: Custom click handler stops the Elm text-selection bug from hard-reloading
                    , custom "click"
                        (Decode.succeed
                            { message = Update_Route onClickRoute
                            , stopPropagation = True
                            , preventDefault = True
                            }
                        )
                    , attribute "draggable" "false"
                    ]
                    [ text app.app_displayName ]
                ]
            ]
        , div
            [ class "flex-grow-1 d-flex align-items-center w-100 my-2" ]
            [ p
                [ class "mb-0 text-body-secondary m-item-card-description text-center w-100"

                -- FIX: Stop propagation here so dragging/highlighting this text doesn't trigger the card's onClick
                , custom "click"
                    (Decode.succeed
                        { message = Update_Chain []
                        , stopPropagation = True
                        , preventDefault = False
                        }
                    )
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


viewSortDropdown : Model -> PageApps -> Html Update
viewSortDropdown model pageApps =
    div [ class "d-flex justify-content-start mb-3 gap-2" ]
        [ div [ class "dropdown" ]
            [ Html.button
                [ class "btn btn-sm border text-body dropdown-toggle"
                , attribute "type" "button"
                , attribute "data-testid" "sort-dropdown-button"
                , onClick Update_ToggleAppsSortDropdown
                ]
                [ Html.text <|
                    case model.model_preferences.preferences_sort of
                        PreferencesSort_Random ->
                            "Sort: Random"

                        PreferencesSort_Alphabetical ->
                            "Sort: Alphabetical"
                ]
            , Html.ul
                [ class <|
                    "dropdown-menu dropdown-menu-end shadow"
                        ++ (if model.model_appsSortDropdownOpen then
                                " show"

                            else
                                ""
                           )
                ]
                [ Html.li []
                    [ Html.button
                        [ class "dropdown-item d-flex align-items-center gap-2"
                        , attribute "data-testid" "sort-dropdown-option-random"
                        , onClick
                            (Update_Chain
                                [ Update_SetPreferences
                                    { preferences_install = model.model_preferences.preferences_install
                                    , preferences_theme = model.model_preferences.preferences_theme
                                    , preferences_sort = PreferencesSort_Random
                                    }
                                , Update_ToggleAppsSortDropdown
                                , Update_RouteWithoutHistory (Route_Apps pageApps.pageApps_route)
                                ]
                            )
                        ]
                        [ Main.Icons.iconShuffle, Html.text "Random" ]
                    ]
                , Html.li []
                    [ Html.button
                        [ class "dropdown-item d-flex align-items-center gap-2"
                        , attribute "data-testid" "sort-dropdown-option-alphabetical"
                        , onClick
                            (Update_Chain
                                [ Update_SetPreferences
                                    { preferences_install = model.model_preferences.preferences_install
                                    , preferences_theme = model.model_preferences.preferences_theme
                                    , preferences_sort = PreferencesSort_Alphabetical
                                    }
                                , Update_ToggleAppsSortDropdown
                                , Update_RouteWithoutHistory (Route_Apps pageApps.pageApps_route)
                                ]
                            )
                        ]
                        [ Main.Icons.iconSortAlphaDown, Html.text "Alphabetical" ]
                    ]
                ]
            ]
        , if model.model_preferences.preferences_sort == PreferencesSort_Random then
            div [ class "has-tooltip autohide d-inline-block" ]
                [ Html.button
                    [ class "btn btn-sm border text-body"
                    , attribute "type" "button"
                    , attribute "data-testid" "sort-shuffle-button"
                    , onClick
                        (Update_Chain
                            [ Update_ShuffleApps
                            , Update_RouteWithoutHistory (Route_Apps pageApps.pageApps_route)
                            ]
                        )
                    ]
                    [ Main.Icons.iconShuffle ]
                , div
                    [ class "tooltip bs-tooltip-end"
                    , attribute "role" "tooltip"
                    , style "top" "50%"
                    , style "left" "100%"
                    , style "transform" "translate(0, -50%)"
                    , style "margin-top" "0"
                    , style "margin-left" "8px"
                    ]
                    [ div [ class "tooltip-inner" ] [ Html.text "Shuffle apps (order resets on reload)" ]
                    ]
                ]

          else
            Html.text ""
        ]


viewCategoryFilters : Model -> PageApps -> Html Update
viewCategoryFilters model pageApps =
    let
        allCategories =
            model.model_config.config_apps
                |> Dict.values
                |> List.concatMap .app_categories
                |> List.Extra.unique
                |> List.sort

        viewCategory category =
            let
                isSelected =
                    pageApps.pageApps_route.routeApps_category == Just category

                btnClass =
                    if isSelected then
                        "list-group-item list-group-item-action active has-tooltip autohide"
                    else
                        "list-group-item list-group-item-action has-tooltip autohide"

                newCategory =
                    if isSelected then
                        Nothing
                    else
                        Just category
                        
                desc =
                    Dict.get category model.model_config.config_categories
                        |> Maybe.map .category_description
                        |> Maybe.withDefault ""
            in
            Html.button
                [ class btnClass
                , attribute "data-testid" ("category-filter-" ++ category)
                , title desc
                , onClick (Update_CategoryFilter newCategory)
                ]
                [ Html.text category ]
    in
    if List.isEmpty allCategories then
        Html.text ""

    else
        div [ class "list-group shadow-sm" ]
            (allCategories |> List.map viewCategory)
