module Main.View exposing (..)

import AppUrl
import Dict
import Html exposing (Html, a, button, code, div, footer, h2, h5, h6, header, img, input, li, main_, p, section, small, span, text, ul)
import Html.Attributes exposing (attribute, class, href, id, placeholder, rel, src, style, tabindex, target, title, type_, value, width)
import Html.Events exposing (onInput, preventDefaultOn, stopPropagationOn)
import Json.Decode as Decode
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Error
import Main.Helpers.AppUrl as AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Markdown as Markdown
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route as Route exposing (..)
import Main.Subscriptions exposing (decodeEscapeKey)
import Main.Update exposing (..)
import Main.View.Instructions exposing (..)


view : Model -> Html Update
view model =
    div
        [ class "min-vh-100 container d-flex flex-column" ]
        [ header
            [ class "py-3" ]
            [ div
                [ class "d-flex align-items-center gap-2 gap-md-3" ]
                [ viewTitle
                , div [ class "flex-grow-1" ]
                    [ model |> viewSearchInput ]
                , div
                    [ class "d-none d-md-flex align-items-center gap-4" ]
                    [ -- viewPackagesLink
                      viewRecipeOptionsLink
                    , model |> viewThemeToggle
                    ]
                , button
                    [ class "navbar-toggler d-md-none border-0 p-1"
                    , type_ "button"
                    , attribute "aria-expanded"
                        (if model.model_navbarExpanded then
                            "true"

                         else
                            "false"
                        )
                    , onClick Update_ToggleNavBar
                    ]
                    [ iconList [ "navbar-toggler-icon" ]
                    ]
                ]
            , div
                [ class "collapse d-md-none mt-3"
                , class
                    (if model.model_navbarExpanded then
                        " show"

                     else
                        ""
                    )
                ]
                [ div
                    [ class "card card-body bg-body-tertiary shadow-sm" ]
                    [ ul [ class "nav flex-column gap-2" ]
                        [ -- li [ class "nav-item" ] [ viewPackagesLink ]
                          li [ class "nav-item" ] [ viewRecipeOptionsLink ]
                        , li [ class "nav-item mt-2 pt-2 border-top" ] [ model |> viewThemeToggle ]
                        ]
                    ]
                ]
            ]
        , div []
            (model.model_errors
                |> List.map
                    (\error ->
                        div [ class "alert alert-danger" ]
                            [ text ("Error: " ++ Main.Error.showError error) ]
                    )
            )
        , main_
            [ class "flex-grow-1" ]
            [ section [] [ model |> viewPage ] ]
        , footer
            [ class "mt-auto py-3 border-top" ]
            [ viewPoweredBy model ]
        ]


viewTitle : Html Update
viewTitle =
    a
        [ href (Route_Search { routeSearch_pattern = "" } |> Route.toString)
        , class "d-flex align-items-center m-0"
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , style "font-size" "1.5rem"
        , style "gap" ".5rem"
        , onClick (Update_Route (Route_Search { routeSearch_pattern = "" }))
        ]
        [ img
            [ src "favicon.svg"
            , class "brand-logo-responsive"
            ]
            []
        , span
            [ class "brand-text fw-bold" ]
            [ text "NGI Forge" ]
        ]


viewSearchInput : Model -> Html Update
viewSearchInput model =
    div
        [ class "name position-relative flex-grow-1"
        , style "max-width" "600px"
        , style "display" "flex"
        , style "justify-content" "between"
        , style "align-items" "center"
        ]
        [ div
            [ class "position-absolute top-50 start-0 translate-middle-y text-secondary"
            , style "pointer-events" "none"
            , style "margin-left" "1.2rem"
            ]
            [ iconSearch ]
        , input
            [ class "form-control bg-transparent"
            , style "padding-left" "2.5rem"
            , style "padding-top" "0.5rem"
            , style "border-radius" "30px"
            , type_ "search"
            , placeholder <|
                case model.model_page of
                    Page_RecipeOptions _ ->
                        "Search options"

                    _ ->
                        "Search apps"
            , value model.model_search
            , id "main-search-bar"
            , onInput (\s -> Update_SearchInput (UpdateSearchInput_Set s))
            , preventDefaultOn "keydown"
                (decodeEscapeKey
                    |> Decode.map (\_ -> ( Update_SearchInput UpdateSearchInput_PreClear, True ))
                )
            ]
            []
        ]


viewRecipeOptionsLink : Html Update
viewRecipeOptionsLink =
    let
        onClickRoute =
            Route_RecipeOptions
                { routeRecipeOptions_pattern = Just ""
                , routeRecipeOptions_page = 1
                , routeRecipeOptions_MaxResultsPerPage = 10
                , routeRecipeOptions_option = Nothing
                }
    in
    a
        [ href (onClickRoute |> Route.toString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0 fw-bold"
        , title "View available recipe options"
        , attribute "aria-label" "View available recipe options"
        , onClick (Update_Route onClickRoute)
        ]
        [ text "Options" ]


viewPackagesLink : Html Update
viewPackagesLink =
    let
        onClickRoute =
            Route_RecipeOptions
                { routeRecipeOptions_pattern = Just ""
                , routeRecipeOptions_page = 1
                , routeRecipeOptions_MaxResultsPerPage = 10
                , routeRecipeOptions_option = Nothing
                }
    in
    a
        [ href (onClickRoute |> Route.toString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0"
        , title "View available packages"
        , attribute "aria-label" "View available packages"
        , onClick (Update_Route onClickRoute)
        ]
        [ text "Packages" ]


viewThemeToggle : Model -> Html Update
viewThemeToggle model =
    span
        [ class "nav-item"
        , style "cursor" "pointer"
        , title "Toggle theme"
        , attribute "aria-label" "Toggle theme"
        , onClick Update_CycleTheme
        ]
        [ case model.model_preferences.preferences_theme of
            PreferencesTheme_Dark ->
                iconMoonStarsFill

            PreferencesTheme_Light ->
                iconSunFill
        ]


viewPage : Model -> Html Update
viewPage model =
    case model.model_page of
        Page_Search ->
            viewPageSearch model

        Page_App pageApp ->
            viewPageApp model pageApp

        Page_RecipeOptions pageRecipeOptions ->
            viewPageRecipeOptions model pageRecipeOptions


viewPageSearch : Model -> Html Update
viewPageSearch model =
    div
        [ class "m-app-grid"
        ]
        (model.model_config.config_apps
            |> Dict.values
            |> (case model.model_search of
                    "" ->
                        identity

                    _ ->
                        List.filter
                            (\app ->
                                let
                                    -- Case Insensitive search
                                    model_search =
                                        String.toLower model.model_search

                                    app_name =
                                        String.toLower app.app_name

                                    app_description =
                                        String.toLower app.app_description

                                    name_matches =
                                        String.contains model_search app_name

                                    desc_matches =
                                        String.contains model_search app_description
                                in
                                name_matches || desc_matches
                            )
               )
            |> List.map (viewPageSearchApp model)
        )


viewPageSearchApp : Model -> App -> Html Update
viewPageSearchApp model app =
    a
        [ href (Route_App (initRouteApp app.app_name) |> Route.toString)
        , class "card m-app-card shadow-sm p-3"
        , style "text-decoration" "none"
        , onClick (Update_Route (Route_App (initRouteApp app.app_name)))
        ]
        [ div
            [ class "w-100"
            , style "display" "flex"
            , style "align-items" "center"
            , style "gap" "12px"
            ]
            [ img
                [ src (getAppIconPath app.app_name)
                , class "app-card-icon"
                , attribute "alt" (app.app_name ++ " icon")
                ]
                []
            , h5 [ class "mb-0" ] [ text app.app_name ]
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
                    [ if app.app_programs.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "shell" ] ]

                      else
                        []
                    , if app.app_container.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "container" ] ]

                      else
                        []
                    , if app.app_vm.enable then
                        [ span [ class "badge bg-secondary me-1" ] [ text "vm" ] ]

                      else
                        []
                    ]
                )
            ]
        ]


viewPageApp : Model -> PageApp -> Html Update
viewPageApp model pageApp =
    div [ class "container" ]
        [ div [ class "row" ]
            [ div
                [ class "col-12 col-lg-9" ]
                [ viewPageAppHeader model pageApp
                , viewDescription model pageApp
                , viewPageAppRun model pageApp
                ]
            , div
                [ class "col-12 col-lg-3 order-lg-first" ]
                [ viewAppResources model pageApp
                , viewAppNgiGrants model pageApp
                ]
            ]
        ]


viewPageAppHeader : Model -> PageApp -> Html Update
viewPageAppHeader model pageApp =
    div
        [ style "display" "flex"
        , style "justify-content" "space-between"
        , style "align-items" "center"
        , class "my-4 mb-4"
        ]
        [ div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "gap" "16px"
            ]
            [ img
                [ src (getAppIconPath pageApp.pageApp_route.routeApp_name)
                , class "app-header-icon"
                , attribute "alt" (pageApp.pageApp_route.routeApp_name ++ " icon")
                ]
                []
            , h2
                [ class "mb-0 fw-bold"
                , style "margin" "0"
                ]
                [ text pageApp.pageApp_route.routeApp_name
                ]
            ]
        , button
            [ class "btn btn-success"
            , let
                route =
                    pageApp.pageApp_route
              in
              onClick (Update_RouteWithoutHistory (Route_App { route | routeApp_runShown = True }))
            ]
            [ text "Run" ]
        ]


viewDescription : Model -> PageApp -> Html Update
viewDescription model pageApp =
    div []
        [ p [ class "lead" ] [ text pageApp.pageApp_app.app_description ]
        , viewInstructionsUsage model pageApp
        ]


viewAppResources : Model -> PageApp -> Html Update
viewAppResources model pageApp =
    let
        links =
            List.filterMap
                (\( linkType, maybeLink ) ->
                    Maybe.map
                        (\url ->
                            li [ class "list-group-item bg-transparent px-0 mb-3" ]
                                [ a
                                    [ href url
                                    , target "_blank"
                                    , rel "noopener"
                                    ]
                                    [ text (showAppLink linkType) ]
                                ]
                        )
                        maybeLink
                )
                [ ( Link_Website, pageApp.pageApp_app.app_links.website )
                , ( Link_Docs, pageApp.pageApp_app.app_links.docs )
                , ( Link_Source, pageApp.pageApp_app.app_links.source )
                ]

        resources =
            links ++ [ viewRecipeLink model pageApp ]
    in
    div
        [ class "box-container target-highlight mb-3"
        , id "resources"
        , tabindex -1
        ]
        [ h6
            [ class "mt-3 mb-3 ms-2"
            ]
            [ text "Resources"
            , a
                [ class "anchor-link"
                , href
                    (model.model_page
                        |> pageToRoute
                        |> Route.toAppUrl
                        |> AppUrl.setFragment (Just "resources")
                        |> AppUrl.toString
                    )
                ]
                []
            ]
        , ul [ class "", style "padding-left" "10px" ]
            resources
        ]


viewAppNgiGrants : Model -> PageApp -> Html msg
viewAppNgiGrants model pageApp =
    let
        subgrants =
            pageApp.pageApp_app.app_ngi.ngi_grants
    in
    if subgrants |> Dict.values |> List.concat |> List.isEmpty then
        text ""

    else
        div
            [ class "box-container target-highlight mb-3"
            , id "grants"
            , tabindex -1
            ]
            [ h6
                [ class "mt-3 mb-3 ms-2"
                ]
                [ text "NGI Grants"
                , a
                    [ class "anchor-link"
                    , href
                        (model.model_page
                            |> pageToRoute
                            |> Route.toAppUrl
                            |> AppUrl.setFragment (Just "grants")
                            |> AppUrl.toString
                        )
                    ]
                    []
                ]
            , div []
                (subgrants
                    |> Dict.toList
                    |> List.map viewGrantCategory
                )
            ]


viewGrantCategory : ( NgiGrantName, List NgiSubgrantName ) -> Html msg
viewGrantCategory ( grant, subgrants ) =
    if List.isEmpty subgrants then
        text ""

    else
        div [ class "container row mb-1" ]
            [ small [ class "col-6" ] [ text grant ]
            , ul [ class "col" ]
                (List.map
                    (\subgrant ->
                        li [ class "list-group-item bg-transparent mb-1" ]
                            [ a
                                [ href ("https://nlnet.nl/project/" ++ subgrant ++ "/")
                                , target "_blank"
                                , rel "noopener noreferrer"
                                ]
                                [ text subgrant ]
                            ]
                    )
                    subgrants
                )
            ]


viewRecipeLink : Model -> PageApp -> Html update
viewRecipeLink model pageApp =
    li [ class "list-group-item bg-transparent px-0" ]
        [ a
            [ href
                (String.join "/"
                    [ model.model_config.config_repository |> showNixUrl
                    , "blob/" ++ commit
                    , model.model_config.config_recipe.configRecipe_apps
                    , pageApp.pageApp_app.app_name ++ "-app"
                    , "recipe.nix"
                    ]
                )
            , target "_blank"
            ]
            [ text "Forge Recipe" ]
        ]


viewPageAppRun : Model -> PageApp -> Html Update
viewPageAppRun model pageApp =
    let
        routeApp =
            pageApp.pageApp_route

        onClickRoute =
            Route_App { routeApp | routeApp_runShown = False }
    in
    if not pageApp.pageApp_route.routeApp_runShown then
        text ""

    else
        div []
            [ div
                [ class "modal show"
                , style "display" "block"
                , tabindex -1
                , style "background-color" "rgba(0,0,0,0.5)"
                , onClick (Update_RouteWithoutHistory onClickRoute)
                ]
                [ div
                    [ class "modal-dialog modal-lg"
                    , stopPropagationOn "click" (Decode.succeed ( Update_NoOp, True ))
                    ]
                    [ div [ class "modal-content" ]
                        [ div [ class "modal-header" ]
                            [ h5 [ class "modal-title" ] [ text ("Run " ++ pageApp.pageApp_route.routeApp_name) ]
                            , button
                                [ class "btn-close"
                                , onClick (Update_RouteWithoutHistory onClickRoute)
                                ]
                                []
                            ]
                        , div [ class "modal-body" ]
                            [ viewPageAppRunOutputs model pageApp
                            , div [ class "tab-content mb-5 p-3 border rounded" ]
                                [ viewPageAppInstructions model pageApp ]
                            ]
                        ]
                    ]
                ]
            ]


viewPageAppRunOutputs : Model -> PageApp -> Html Update
viewPageAppRunOutputs model pageApp =
    ul [ class "nav nav-pills mb-4" ]
        (pageApp.pageApp_app
            |> listAppRuntimeAvailable
            |> List.map (viewPageAppRunOutput model pageApp)
        )


viewPageAppRunOutput : Model -> PageApp -> AppRuntime -> Html Update
viewPageAppRunOutput model pageApp appRuntime =
    li [ class "nav-item" ]
        [ a
            [ class
                ([ "nav-link"
                 , if appRuntime == pageApp.pageApp_runtime then
                    "active"

                   else
                    ""
                 ]
                    |> String.join " "
                )
            , style "cursor" "pointer"
            , style "border" "none"
            , id <| "run-" ++ (showAppRuntime appRuntime |> String.toLower)
            , let
                route =
                    pageApp.pageApp_route
              in
              onClick (Update_RouteWithoutHistory (Route_App { route | routeApp_runRuntime = Just appRuntime }))
            ]
            [ span [ class "fw-bold" ] [ text <| showAppRuntime appRuntime ]
            ]
        ]


viewPageRecipeOptions : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptions model pageRecipeOptions =
    let
        routeRecipeOptions =
            pageRecipeOptions.pageRecipeOptions_route

        routePagePrev =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_page = routeRecipeOptions.routeRecipeOptions_page - 1
                }

        routePageNext =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_page = routeRecipeOptions.routeRecipeOptions_page + 1
                }
    in
    div []
        [ div [ class "list-group" ]
            (model.model_RecipeOptions.modelRecipeOptions_filtered
                |> List.map (viewPageRecipeOption model pageRecipeOptions)
            )
        , div [ class "d-flex justify-content-center align-items-center" ]
            [ if 1 < routeRecipeOptions.routeRecipeOptions_page then
                Html.button
                    [ class "btn"
                    , onClick (Update_Route routePagePrev)
                    ]
                    [ text "Prev" ]

              else
                text ""
            , text (pageRecipeOptions.pageRecipeOptions_route.routeRecipeOptions_page |> String.fromInt)
            , text " / "
            , text (pageRecipeOptions.pageRecipeOptions_LastPage |> String.fromInt)
            , if routeRecipeOptions.routeRecipeOptions_page < pageRecipeOptions.pageRecipeOptions_LastPage then
                Html.button
                    [ class "btn"
                    , onClick (Update_Route routePageNext)
                    ]
                    [ text "Next" ]

              else
                text ""
            ]
        ]


viewPageRecipeOption : Model -> PageRecipeOptions -> ( NixName, NixModuleOption ) -> Html Update
viewPageRecipeOption model pageRecipeOptions ( optionName, option ) =
    let
        routeRecipeOptions =
            pageRecipeOptions.pageRecipeOptions_route

        onClickRoute =
            Route_RecipeOptions
                { routeRecipeOptions
                    | routeRecipeOptions_option = Just optionName
                }
    in
    a
        [ class "recipe-option list-group-item list-group-item-action flex-column align-items-start"
        , href (onClickRoute |> Route.toString)
        , id optionName
        , onClick (Update_Route onClickRoute)
        ]
        [ div [ class "d-flex w-100 justify-content-between" ]
            [ h5
                [ class "mb-1"
                ]
                [ code [] [ text optionName ]
                ]
            ]
        , div []
            [ span [ class "fw-bold" ] [ text "Type: " ]
            , code [] [ text option.nixModuleOption_type ]
            ]
        , div []
            [ span [ class "fw-bold" ] [ text "Description: " ]
            , div []
                (option.nixModuleOption_description
                    |> Markdown.render
                )
            ]
        ]


viewPoweredBy : Model -> Html update
viewPoweredBy model =
    div
        [ class "text-secondary"
        , style "display" "flex"
        , style "flex-wrap" "wrap"
        , style "flex-direction" "row"
        , style "justify-content" "space-evenly"
        , style "column-gap" "1ex"
        , style "font-size" "0.8em"
        ]
        [ span []
            [ text "Powered by "
            , a [ href "https://nixos.org", target "_blank" ] [ text "Nix" ]
            , text ", "
            , a
                [ href "https://github.com/NixOS/nixpkgs"
                , target "_blank"
                ]
                [ text "Nixpkgs" ]
            , text " and "
            , a [ href "https://elm-lang.org", target "_blank" ] [ text "Elm" ]
            , text "."
            ]
        , span []
            [ text "Developed by "
            , a
                [ href "https://nixos.org/community/teams/ngi/"
                , target "_blank"
                ]
                [ text "Nix@NGI team" ]
            , text "."
            ]
        , span []
            [ text " Contribute or report issues at "
            , a
                [ href (model.model_config.config_repository |> showNixUrl)
                , target "_blank"
                ]
                [ text (model.model_config.config_repository |> showGithubRepoSlug) ]
            , text "."
            ]
        , span []
            [ text " Version "
            , a
                [ href ((model.model_config.config_repository |> showNixUrl) ++ "/tree/" ++ commit)
                , target "_blank"
                ]
                [ text shortCommit ]
            , text "."
            ]
        ]
