module Main.View exposing (..)

import Html exposing (Html, a, button, div, footer, header, img, input, li, main_, section, span, text, ul)
import Html.Attributes exposing (attribute, class, href, id, placeholder, src, style, target, title, type_, value)
import Html.Events exposing (onInput, preventDefaultOn)
import Json.Decode as Decode
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Model.Route exposing (..)
import Main.Subscriptions exposing (decodeEscapeKey)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Error exposing (..)
import Main.View.Page exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Page.Apps exposing (..)
import Main.View.Page.Packages exposing (..)
import Main.View.Page.Recipe exposing (..)


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
                    [ viewSearchInput model ]
                , div
                    [ class "d-none d-md-flex align-items-center gap-4" ]
                    [ viewPagePackagesLink
                    , viewPageRecipeOptionsLink Layout_Desktop
                    , viewDocsLink
                    , viewThemeToggle model
                    ]
                , button
                    [ class "navbar-toggler d-md-none border-0 p-1"
                    , type_ "button"
                    , attribute "data-testid" "navbar-toggler"
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
                        [ li [ class "nav-item" ] [ viewPagePackagesLink ]
                        , li [ class "nav-item" ] [ viewPageRecipeOptionsLink Layout_Mobile ]
                        , li [ class "nav-item" ] [ viewDocsLink ]
                        , li [ class "nav-item mt-2 pt-2 border-top" ] [ viewThemeToggle model ]
                        ]
                    ]
                ]
            ]
        , viewErrors model
        , main_
            [ class "flex-grow-1" ]
            [ section [] [ viewPage model ] ]
        , footer
            [ class "mt-3 py-3 border-top" ]
            [ viewPoweredBy model ]
        ]


viewTitle : Html Update
viewTitle =
    let
        onClickRoute =
            Route_Apps defaultRouteApps
    in
    a
        [ href (onClickRoute |> routeToString)
        , class "d-flex align-items-center m-0"
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , style "font-size" "1.5rem"
        , style "gap" ".5rem"
        , onClick (Update_Route onClickRoute)
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


{-| Note: Docs is not an elm route
-}
viewDocsLink : Html Update
viewDocsLink =
    a
        [ href "docs"
        , target "_blank"
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0 fw-bold"
        ]
        [ text "Docs" ]


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
                    Page_App _ ->
                        "Search apps"

                    Page_Apps _ ->
                        "Search apps"

                    Page_Packages _ ->
                        "Search packages"

                    Page_RecipeOptions page ->
                        "Search options"
                            ++ (case page.pageRecipeOptions_route.routeRecipeOptions_scope of
                                    [] ->
                                        ""

                                    scope ->
                                        " in " ++ joinNixAttrPath scope
                               )
            , value model.model_search
            , id "main-search-bar"
            , attribute "data-testid" "main-search-bar"
            , onInput (\pattern -> Update_Search pattern)
            , preventDefaultOn "keydown"
                (decodeEscapeKey
                    |> Decode.map (\_ -> ( Update_Search "", True ))
                )
            ]
            []
        ]


viewThemeToggle : Model -> Html Update
viewThemeToggle model =
    span
        [ class "nav-item"
        , style "cursor" "pointer"
        , title "Toggle theme"
        , attribute "aria-label" "Toggle theme"
        , attribute "data-testid" "theme-toggle-btn"
        , onClick Update_CycleTheme
        ]
        [ case model.model_preferences.preferences_theme of
            PreferencesTheme_Dark ->
                iconMoonStarsFill

            PreferencesTheme_Light ->
                iconSunFill
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
            , text ", "
            , a
                [ href "https://github.com/weyl-ai/nimi"
                , target "_blank"
                ]
                [ text "Nimi" ]
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
                [ href model.model_config.config_repository.repository_homeUrl
                , target "_blank"
                ]
                [ text model.model_config.config_repository.repository_path ]
            , text "."
            ]
        , span []
            [ text " Version "
            , a
                [ href model.model_config.config_repository.repository_treeUrl
                , target "_blank"
                ]
                [ text model.model_config.config_repository.repository_commitRef ]
            , text "."
            ]
        ]
