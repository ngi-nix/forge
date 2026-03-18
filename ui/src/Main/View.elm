module Main.View exposing (..)

import Dict
import Html exposing (Html, a, button, div, footer, form, h2, h5, header, input, li, main_, nav, p, section, small, span, text, ul)
import Html.Attributes exposing (class, href, name, placeholder, style, tabindex, target, type_, value)
import Html.Events exposing (onInput, stopPropagationOn)
import Json.Decode as Decode
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Error
import Main.Helpers.Html exposing (..)
import Main.Model exposing (..)
import Main.Route as Route exposing (..)
import Main.Update exposing (..)
import Main.View.Instructions exposing (..)


view : Model -> Html Update
view model =
    div
        [ class "min-vh-100 container"
        , style "display" "flex"
        , style "flex-direction" "column"
        ]
        [ header
            [ class "py-3" ]
            [ nav
                [ class "navbar navbar-expand-lg"
                ]
                [ viewTitle
                , model |> viewSearchInput
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
            [ viewPoweredBy ]
        ]


viewTitle : Html Update
viewTitle =
    a
        [ href "/"
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "navbar-brand px-2"
        , onClick (Update_Route (Route_Search { routeSearch_pattern = "" }))
        ]
        [ text "NGI Nix Forge" ]


viewSearchInput : Model -> Html Update
viewSearchInput model =
    div
        [ class "name px-2"
        , style "display" "flex"
        , style "justify-content" "between"
        , style "align-items" "center"
        ]
        [ form [ class "d-flex" ]
            [ input
                [ class "form-control me-2"
                , type_ "search"
                , placeholder "Search"
                , value model.model_search
                , onInput (\search -> Update_Route (Route_Search { routeSearch_pattern = search }))
                ]
                []
            , button
                [ class "btn btn-outline-success"
                , type_ "submit"
                ]
                [ text "Search" ]
            ]
        ]


viewPage : Model -> Html Update
viewPage model =
    case model.model_page of
        Page_Search ->
            viewPageSearch model

        Page_App pageApp ->
            viewPageApp model pageApp


viewPageSearch : Model -> Html Update
viewPageSearch model =
    div
        [ class "container m-app-grid"
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
            , small
                [ class "text-muted"
                , style "font-style" "italic"
                ]
                [ text ("v" ++ app.app_version) ]
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
                        [ span [ class "badge bg-secondary me-1" ] [ text "programs" ] ]

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
    div []
        [ div
            [ style "display" "flex"
            , style "justify-content" "space-between"
            , style "align-items" "center"
            , style "margin-bottom" "1rem"
            , style "border-bottom" "1px solid #dee2e6"
            , style "padding-bottom" "0.5rem"
            ]
            [ div []
                [ h2 [ style "margin" "0" ] [ text pageApp.pageApp_route.routeApp_name ]
                , text ("v" ++ pageApp.pageApp_app.app_version)
                ]
            , Html.button
                [ class "btn btn-success"
                , let
                    route =
                        pageApp.pageApp_route
                  in
                  onClick (Update_Route (Route_App { route | routeApp_runShown = True }))
                ]
                [ text "Run" ]
            ]
        , div [ class "lead mb-4" ]
            [ text pageApp.pageApp_app.app_description ]
        , viewPageAppRun model pageApp
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
                            , Html.button
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
                AppOutput_Programs ->
                    pageApp.pageApp_app.app_programs.enable

                AppOutput_Container ->
                    pageApp.pageApp_app.app_container.enable

                AppOutput_VM ->
                    pageApp.pageApp_app.app_vm.enable
    in
    ul [ class "nav nav-pills mb-4" ]
        ([ AppOutput_Programs
         , AppOutput_Container
         , AppOutput_VM
         ]
            |> List.filter enabled
            |> List.map (viewPageAppRunOuput model pageApp)
        )


viewPageAppRunOuput : Model -> PageApp -> AppOutput -> Html Update
viewPageAppRunOuput model pageApp appOutput =
    li [ class "nav-item" ]
        [ Html.button
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
            , let
                route =
                    pageApp.pageApp_route
              in
              onClick (Update_Route (Route_App { route | routeApp_runOutput = Just appOutput }))
            ]
            [ text <| showAppOutput appOutput
            ]
        ]


viewPoweredBy : Html update
viewPoweredBy =
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
            ]
        , span []
            [ text "Developed by "
            , a
                [ href "https://nixos.org/community/teams/ngi/"
                , target "_blank"
                ]
                [ text "Nix@NGI team" ]
            ]
        , span []
            [ text " Contribute or report issues at "
            , a
                [ href "https://github.com/ngi-nix/ngi-nix-forge"
                , target "_blank"
                ]
                [ text "ngi-nix/ngi-nix-forge" ]
            ]
        , let
            commit =
                ":master"
          in
          if not (String.contains "master" commit) then
            span []
                [ text " Version "
                , a
                    [ href ("https://github.com/ngi-nix/ngi-nix-forge/commit/" ++ commit)
                    , target "_blank"
                    ]
                    [ text commit ]
                ]

          else
            text ""
        ]
