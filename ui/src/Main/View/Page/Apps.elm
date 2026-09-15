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
    let
        reRoute =
            \modifyRoutePagination ->
                let
                    routeApps =
                        pageApps.pageApps_route
                in
                Route_Apps
                    { routeApps
                        | routeApps_pagination = routeApps.routeApps_pagination |> modifyRoutePagination
                    }
    in
    div [ class "row" ]
        [ div [ class "col-md-12 mt-1 mb-1" ]
            [ div
                [ style "display" "grid"
                , style "grid-template-columns" "1fr auto 1fr"
                , class "align-items-center my-2"
                ]
                [ div [ class "d-flex justify-content-start align-items-center gap-2" ]
                    [ viewAppsCount model pageApps
                    , viewCategoryDropdown model pageApps
                    , viewSortDropdown model pageApps
                    ]
                , viewPaginationNavigation PaginationVisibility_HiddenIfSinglePage pageApps.pageApps_pagination reRoute
                , text ""
                ]
            , viewPageAppsPagination
                pageApps.pageApps_pagination
                (viewPageAppsApp model pageApps)
                reRoute
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


viewAppsCount : Model -> PageApps -> Html Update
viewAppsCount model pageApps =
    let
        globalTotal =
            Dict.size model.model_config.config_apps

        filtered =
            pageApps.pageApps_pagination.pagePagination_list
                |> List.concat
                |> List.length

        hasSearch =
            pageApps.pageApps_route.routeApps_search /= ""

        hasCategory =
            pageApps.pageApps_route.routeApps_category

        activeTotal =
            case hasCategory of
                Just cat ->
                    model.model_config.config_apps
                        |> Dict.values
                        |> List.filter (\a -> List.member cat a.app_categories)
                        |> List.length

                Nothing ->
                    globalTotal

        noun =
            if hasSearch then
                "applications matching \"" ++ pageApps.pageApps_route.routeApps_search ++ "\""

            else
                "applications"
    in
    viewCountWidget
        { total = activeTotal
        , filtered = filtered
        , noun = noun
        , testId = "apps-count-badge"
        }


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
    div [ class "d-flex justify-content-start align-items-center gap-2" ]
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


viewCategoryDropdown : Model -> PageApps -> Html Update
viewCategoryDropdown model pageApps =
    let
        allCategories =
            model.model_config.config_apps
                |> Dict.values
                |> List.concatMap .app_categories
                |> List.Extra.unique
                |> List.sort

        filteredCategories =
            if model.model_appsCategorySearch == "" then
                allCategories

            else
                allCategories |> List.filter (\c -> String.contains (String.toLower model.model_appsCategorySearch) (String.toLower c))

        currentCat =
            pageApps.pageApps_route.routeApps_category |> Maybe.withDefault "All"

        isDropdownOpen =
            model.model_appsCategoryDropdownOpen

        -- Ensure the dropdown closes when clicking outside by rendering an invisible full-screen overlay
        overlay =
            if isDropdownOpen then
                div
                    [ class "position-fixed top-0 start-0 w-100 h-100"
                    , style "z-index" "1040"
                    , onClick
                        (Update_Chain
                            [ Update_ToggleAppsCategoryDropdown
                            , Update_CategorySearch ""
                            ]
                        )
                    ]
                    []

            else
                Html.text ""
    in
    div [ class "dropdown d-inline-block" ]
        [ overlay
        , Html.button
            [ class "btn btn-sm border text-body dropdown-toggle"
            , attribute "type" "button"
            , attribute "data-testid" "category-dropdown-button"
            , style "position" "relative"
            , style "z-index"
                (if isDropdownOpen then
                    "1050"

                 else
                    "auto"
                )
            , onClick Update_ToggleAppsCategoryDropdown
            ]
            [ Html.text ("Category: " ++ currentCat) ]
        , div
            [ class <|
                "dropdown-menu shadow p-0"
                    ++ (if isDropdownOpen then
                            " show"

                        else
                            ""
                       )
            , style "min-width" "240px"
            , style "border-radius" "0.5rem"
            , style "overflow" "hidden"
            , style "z-index" "1050"
            ]
            [ div [ class "p-2 border-bottom bg-body", style "position" "sticky", style "top" "0", style "z-index" "1" ]
                [ Html.input
                    [ class "form-control form-control-sm"
                    , Html.Attributes.id "category-search-input"
                    , attribute "placeholder" "Search categories..."
                    , Html.Attributes.value model.model_appsCategorySearch
                    , Html.Events.onInput Update_CategorySearch
                    , preventDefaultOn "keydown" decodeCategoryKey
                    , stopPropagationOn "click" (Decode.succeed ( Update_NoOp, True ))

                    -- The global Escape listener in Subscriptions.elm will handle Esc key
                    ]
                    []
                ]
            , Html.ul
                [ class "list-unstyled mb-0 py-1"
                , style "max-height" "300px"
                , style "overflow-y" "auto"
                ]
                (let
                    finalCategoriesList =
                        if model.model_appsCategorySearch == "" then
                            Nothing :: List.map Just filteredCategories

                        else
                            List.map Just filteredCategories ++ [ Nothing ]

                    categoryItemsHtml =
                        if List.isEmpty finalCategoriesList then
                            [ Html.li [ class "px-3 py-2 text-muted small text-center" ]
                                [ Html.text "No categories found" ]
                            ]

                        else
                            finalCategoriesList
                                |> List.indexedMap
                                    (\idx catMaybe ->
                                        let
                                            isHighlighted =
                                                model.model_appsCategorySearchIndex == idx

                                            isActive =
                                                pageApps.pageApps_route.routeApps_category == catMaybe

                                            highlightClass =
                                                if isHighlighted then
                                                    " keyboard-focused"

                                                else
                                                    ""

                                            activeClass =
                                                if isActive then
                                                    " active"

                                                else
                                                    ""

                                            catText =
                                                case catMaybe of
                                                    Nothing ->
                                                        "All Categories"

                                                    Just c ->
                                                        c

                                            testId =
                                                case catMaybe of
                                                    Nothing ->
                                                        "category-filter-All"

                                                    Just c ->
                                                        "category-filter-" ++ c
                                        in
                                        Html.li []
                                            [ Html.button
                                                [ Html.Attributes.id testId
                                                , attribute "data-testid" testId
                                                , class ("dropdown-item d-flex justify-content-between align-items-center" ++ activeClass ++ highlightClass)
                                                , onClick
                                                    (Update_Chain
                                                        [ Update_CategoryFilter catMaybe
                                                        , Update_ToggleAppsCategoryDropdown
                                                        , Update_CategorySearch ""
                                                        ]
                                                    )
                                                ]
                                                [ Html.text catText ]
                                            ]
                                    )
                 in
                 categoryItemsHtml
                )
            ]
        ]


decodeCategoryKey : Decode.Decoder ( Update, Bool )
decodeCategoryKey =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                case key of
                    "ArrowUp" ->
                        Decode.succeed ( Update_CategorySearchMove -1, True )

                    "ArrowDown" ->
                        Decode.succeed ( Update_CategorySearchMove 1, True )

                    "Enter" ->
                        Decode.succeed ( Update_CategorySearchSelect, True )

                    _ ->
                        Decode.fail "Not a navigation key"
            )
