module Main.View exposing (..)

import Dict
import Html exposing (Html, a, button, code, div, footer, h3, h5, h6, header, img, input, li, main_, p, section, small, span, text, ul)
import Html.Attributes exposing (attribute, class, href, id, name, placeholder, rel, src, style, tabindex, target, title, type_, value, width)
import Html.Events exposing (onInput, preventDefaultOn, stopPropagationOn)
import Json.Decode as Decode
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Error
import Main.Helpers.Html exposing (..)
import Main.Helpers.Markdown as Markdown
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Route as Route exposing (..)
import Main.Subscriptions exposing (decodeEscapeKey)
import Main.Theme exposing (Theme(..))
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
                    [ viewPackagesLink
                    , viewRecipeOptionsLink
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
                    [ span [ class "navbar-toggler-icon" ] []
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
                        [ li [ class "nav-item" ] [ viewPackagesLink ]
                        , li [ class "nav-item" ] [ viewRecipeOptionsLink ]
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
        , onClick (Update_Route (Route_Search { routeSearch_pattern = "" }))
        ]
        [ img [ src "favicon.svg", width 35 ] []
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
    a
        [ href (Route_RecipeOptions { routeRecipeOptions_pattern = Just "" } |> Route.toString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0"
        , title "View available recipe options"
        , attribute "aria-label" "View available recipe options"
        , onClick (Update_Route (Route_RecipeOptions { routeRecipeOptions_pattern = Just "" }))
        ]
        [ text "Options" ]


viewPackagesLink : Html Update
viewPackagesLink =
    a
        [ href (Route_RecipeOptions { routeRecipeOptions_pattern = Just "" } |> Route.toString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0"
        , title "View available packages"
        , attribute "aria-label" "View available packages"
        , onClick (Update_Route (Route_RecipeOptions { routeRecipeOptions_pattern = Just "" }))
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
        [ case model.model_preferences.pref_theme of
            Theme_Dark ->
                iconMoonStarsFill

            Theme_Light ->
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
            [ name ("app-" ++ app.app_name)
            , class "w-100"
            , style "display" "flex"
            , style "justify-content" "space-between"
            ]
            [ h5 [ class "mb-1" ] [ text app.app_name ]
            ]
        , p
            [ class "mb-1"
            ]
            [ text app.app_description ]
        , p
            [ class "mb-1 "
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
                [ viewTabResources model pageApp
                , viewTabNgiGrants model pageApp
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
        [ div []
            [ h3 [ style "margin" "0" ]
                [ text pageApp.pageApp_route.routeApp_name
                ]
            ]
        , button
            [ class "btn btn-success"
            , let
                route =
                    pageApp.pageApp_route
              in
              onClick (Update_Route (Route_App { route | routeApp_runShown = True }))
            ]
            [ text "Run" ]
        ]


viewDescription : Model -> PageApp -> Html Update
viewDescription model pageApp =
    div []
        [ p [ class "lead" ] [ text pageApp.pageApp_app.app_description ]
        , viewInstructionsUsage model pageApp
        ]


viewTabResources : Model -> PageApp -> Html Update
viewTabResources model pageApp =
    div [ class "box-container mb-3" ]
        [ h6
            [ class "mt-3 mb-3 ms-2"
            , id "resources"
            ]
            [ text "Resources"
            , a
                [ class "anchor-link"
                , href "/app/python-web-app?runOutput=shell#resources"
                ]
                []
            ]
        , ul [ class "", style "padding-left" "10px" ]
            [ li [ class "list-group-item bg-transparent px-0 mb-3" ]
                [ a
                    [ href "#"
                    , target "_blank"
                    , rel "noopener"
                    ]
                    [ text "Homepage" ]
                ]
            , li
                [ class "list-group-item bg-transparent px-0 mb-3"
                ]
                [ a
                    [ href "#"
                    , target "_blank"
                    , rel "noopener"
                    ]
                    [ text "Documentation" ]
                ]
            , li [ class "list-group-item bg-transparent px-0 mb-3" ]
                [ a
                    [ href "#"
                    , target "_blank"
                    , rel "noopener"
                    ]
                    [ text "Source Repository" ]
                ]
            , viewRecipeLink model pageApp
            ]
        ]


viewTabNgiGrants : Model -> PageApp -> Html msg
viewTabNgiGrants model pageApp =
    let
        subgrants =
            pageApp.pageApp_app.app_grants
    in
    if hasAnyGrants subgrants then
        div [ class "box-container mb-3" ]
            [ h6
                [ class "mt-3 mb-3 ms-2"
                , id "grants"
                ]
                [ text "NGI Grants"
                , a
                    [ class "anchor-link"
                    , href "/app/python-web-app?runOutput=shell#grants"
                    ]
                    []
                ]
            , div []
                [ viewGrantCategory "Commons" subgrants.commons
                , viewGrantCategory "Core" subgrants.core
                , viewGrantCategory "Entrust" subgrants.entrust
                , viewGrantCategory "Review" subgrants.review
                ]
            ]

    else
        text ""


hasAnyGrants : AppNgiSubgrants -> Bool
hasAnyGrants subgrants =
    not (List.isEmpty subgrants.commons)
        || not (List.isEmpty subgrants.core)
        || not (List.isEmpty subgrants.entrust)
        || not (List.isEmpty subgrants.review)


viewGrantCategory : String -> List String -> Html msg
viewGrantCategory categoryName grants =
    if List.isEmpty grants then
        text ""

    else
        div [ class "container row mb-1" ]
            [ small [ class "col-6" ] [ text categoryName ]
            , ul [ class "col" ]
                (List.map
                    (\grantName ->
                        li [ class "list-group-item bg-transparent mb-1" ]
                            [ a
                                [ href ("https://nlnet.nl/project/" ++ grantName ++ "/")
                                , target "_blank"
                                , rel "noopener noreferrer"
                                ]
                                [ text grantName ]
                            ]
                    )
                    grants
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
                    , pageApp.pageApp_app.app_name
                    , "recipe.nix"
                    ]
                )
            , target "_blank"
            ]
            [ text "Forge Recipe" ]
        ]


viewPageAppRun : Model -> PageApp -> Html Update
viewPageAppRun model pageApp =
    if not pageApp.pageApp_route.routeApp_runShown then
        text ""

    else
        div []
            [ div
                [ class "modal show"
                , style "display" "block"
                , tabindex -1
                , style "background-color" "rgba(0,0,0,0.5)"
                , let
                    route =
                        pageApp.pageApp_route
                  in
                  onClick (Update_Route (Route_App { route | routeApp_runShown = False }))
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
                                , let
                                    route =
                                        pageApp.pageApp_route
                                  in
                                  onClick (Update_Route (Route_App { route | routeApp_runShown = False }))
                                ]
                                []
                            ]
                        , div [ class "modal-body" ]
                            [ viewPageAppRunOuputs model pageApp
                            , div [ class "tab-content mb-5 p-3 border rounded" ]
                                [ viewPageAppInstructions model pageApp ]
                            ]
                        ]
                    ]
                ]
            ]


viewPageAppRunOuputs : Model -> PageApp -> Html Update
viewPageAppRunOuputs model pageApp =
    let
        enabled : AppOutput -> Bool
        enabled tab =
            case tab of
                AppOutput_Shell ->
                    pageApp.pageApp_app.app_programs.enable

                AppOutput_Container ->
                    pageApp.pageApp_app.app_container.enable

                AppOutput_VM ->
                    pageApp.pageApp_app.app_vm.enable
    in
    ul [ class "nav nav-pills mb-4" ]
        ([ AppOutput_Shell
         , AppOutput_Container
         , AppOutput_VM
         ]
            |> List.filter enabled
            |> List.map (viewPageAppRunOuput model pageApp)
        )


viewPageAppRunOuput : Model -> PageApp -> AppOutput -> Html Update
viewPageAppRunOuput model pageApp appOutput =
    li [ class "nav-item" ]
        [ a
            [ class
                ([ "nav-link"
                 , if Just appOutput == pageApp.pageApp_route.routeApp_runOutput then
                    "active"

                   else
                    ""
                 ]
                    |> String.join " "
                )
            , style "cursor" "pointer"
            , style "border" "none"
            , id <| "run-" ++ (showAppOutput appOutput |> String.toLower)
            , let
                route =
                    pageApp.pageApp_route
              in
              onClick (Update_Route (Route_App { route | routeApp_runOutput = Just appOutput }))
            ]
            [ text <| showAppOutput appOutput
            ]
        ]


viewPageRecipeOptions : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptions model pageRecipeOptions =
    div [ class "list-group" ]
        (model.model_RecipeOptions.modelRecipeOptions_filtered
            |> Dict.toList
            |> List.map (viewPageRecipeOption model pageRecipeOptions)
        )


viewPageRecipeOption : Model -> PageRecipeOptions -> ( NixName, NixModuleOption ) -> Html Update
viewPageRecipeOption model pageRecipeOptions ( optionName, option ) =
    a
        [ class "list-group-item list-group-item-action flex-column align-items-start"
        , href (Route_RecipeOptions { routeRecipeOptions_pattern = Just optionName } |> Route.toString)
        , onClick (Update_Route (Route_RecipeOptions { routeRecipeOptions_pattern = Just optionName }))
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
