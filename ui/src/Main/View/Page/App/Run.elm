module Main.View.Page.App.Run exposing (..)

import Html exposing (Html, a, br, button, details, div, h5, hr, li, p, small, span, summary, text, ul)
import Html.Attributes exposing (attribute, class, href, id, style, tabindex, target, title)
import Html.Events exposing (stopPropagationOn)
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
import Main.Update exposing (..)
import Main.Update.Types exposing (..)


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
                , attribute "data-testid" "run-modal-container"
                , tabindex -1
                , style "background-color" "rgba(0,0,0,0.5)"
                , onClick (Update_RouteWithoutHistory onClickRoute)
                ]
                [ div
                    [ class "modal-dialog modal-lm-custom"
                    , stopPropagationOn "click" (Decode.succeed ( Update_NoOp, True ))
                    ]
                    [ div [ class "modal-content" ]
                        [ div [ class "modal-header" ]
                            [ h5 [ class "modal-title" ] [ text pageApp.pageApp_app.app_displayName ]
                            , button
                                [ class "btn-close"
                                , attribute "data-testid" "close-modal-button"
                                , onClick (Update_RouteWithoutHistory onClickRoute)
                                ]
                                []
                            ]
                        , div [ class "modal-body" ]
                            [ viewPageAppRunRuntimes model pageApp
                            , div [ class "tab-content mb-5 p-3 border rounded" ]
                                [ viewPageAppRunInstructions model pageApp ]
                            ]
                        ]
                    ]
                ]
            ]


viewPageAppRunRuntimes : Model -> PageApp -> Html Update
viewPageAppRunRuntimes model pageApp =
    ul [ class "nav nav-pills mb-4" ]
        (pageApp.pageApp_app
            |> listAppRuntimeAvailable
            |> List.map (viewPageAppRunRuntime model pageApp)
        )


viewPageAppRunRuntime : Model -> PageApp -> AppRuntime -> Html Update
viewPageAppRunRuntime _ pageApp appRuntime =
    li [ class "nav-item" ]
        [ a
            [ class
                ([ "nav-link"
                 , if Just appRuntime == pageApp.pageApp_runtime then
                    "active"

                   else
                    ""
                 ]
                    |> String.join " "
                )
            , style "cursor" "pointer"
            , style "border" "none"
            , attribute "role" "tab"
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


viewPageAppRunInstructions : Model -> PageApp -> Html Update
viewPageAppRunInstructions model pageApp =
    div [] <|
        case pageApp.pageApp_runtime of
            Nothing ->
                []

            Just appRuntime ->
                [ viewPageAppRunNixInstall model pageApp
                , hr [] []
                , div [ class "d-flex justify-content-end align-items-center mb-2" ]
                    [ a
                        [ href ("docs/manuals/contributor/how_to/app_recipe.html#" ++ (showAppRuntime appRuntime |> String.toLower) ++ "-runtime")
                        , class "d-flex align-items-center gap-1 text-decoration-none"
                        , target "_blank"
                        , title "Runtime Documentation"
                        ]
                        [ iconBookHalf
                        , text "Docs"
                        ]
                    ]
                , case appRuntime of
                    AppRuntime_Program ->
                        if pageApp.pageApp_app.app_programs.appPrograms_runtimes.appProgramsRuntimes_program.enable then
                            viewPageAppRunProgram model pageApp

                        else
                            text ""

                    AppRuntime_Shell ->
                        if pageApp.pageApp_app.app_programs.appPrograms_runtimes.appProgramsRuntimes_shell.enable then
                            viewPageAppRunShell model pageApp

                        else
                            text ""

                    AppRuntime_Container ->
                        if pageApp.pageApp_app.app_services.appServices_runtimes.appServicesRuntimes_container.enable then
                            viewPageAppRunContainer model pageApp

                        else
                            text ""

                    AppRuntime_NixOS ->
                        if pageApp.pageApp_app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
                            viewPageAppRunNixOS model pageApp

                        else
                            text ""
                ]


viewPageAppRunNixInstall : Model -> PageApp -> Html Update
viewPageAppRunNixInstall _ _ =
    div [ class "accordion" ]
        [ details [ class "accordion-item" ]
            [ summary [ class "accordion-button accordion-header fw-bold" ]
                [ text "Install Nix" ]
            , div [ class "accordion-body" ]
                [ p [ class "mb-1" ]
                    [ text "1. Install Nix "
                    , a [ href "https://github.com/NixOS/nix-installer#nix-installer", target "_blank" ]
                        [ text "(learn more about this installer)." ]
                    ]
                , bashCodeBlock "curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes"
                , small [ class "mb-1" ]
                    [ text "to uninstall, run:" ]
                , bashCodeBlock "/nix/nix-installer uninstall"
                , p [ class "mt-3 mb-1" ]
                    [ text "2. Accept binaries pre-built by NGI Forge (optional, highly recommended) " ]
                , bashCodeBlock "export NIX_CONFIG=\"accept-flake-config = true\""
                ]
            ]
        ]


viewPageAppRunProgram : Model -> PageApp -> Html Update
viewPageAppRunProgram model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ]
            [ text "Launch the program" ]
        , br [] []
        , bashCodeBlock <|
            String.concat
                [ "nix run "
                , showForgeInputFlakes model
                , "#"
                , pageApp.pageApp_app.app_outputName
                , ".program"
                ]
        ]


viewPageAppRunShell : Model -> PageApp -> Html Update
viewPageAppRunShell model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ]
            [ text "Enter a shell environment with CLI or GUI programs available" ]
        , br [] []
        , bashCodeBlock <|
            String.concat
                [ "nix shell "
                , showForgeInputFlakes model
                , "#"
                , pageApp.pageApp_app.app_outputName
                ]
        ]


viewPageAppRunContainer : Model -> PageApp -> Html Update
viewPageAppRunContainer model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ] [ text "Run application services in OCI containers" ]
        , br [] []
        , bashCodeBlock <|
            String.concat
                [ "nix run "
                , showForgeInputFlakes model
                , "#"
                , pageApp.pageApp_app.app_outputName
                , ".container"
                ]
        , hr [] []
        , viewPageAppRunContainerBuildOCI model pageApp
        ]


viewPageAppRunContainerBuildOCI : Model -> PageApp -> Html Update
viewPageAppRunContainerBuildOCI model pageApp =
    details []
        [ summary [] [ text "Build container images manually" ]
        , br [] []
        , bashCodeBlock <|
            String.join "\n"
                [ String.concat
                    [ "nix build "
                    , showForgeInputFlakes model
                    , "#"
                    , pageApp.pageApp_app.app_outputName
                    , ".container"
                    ]
                , ""
                , "./result/bin/build-oci-images"
                ]
        ]


viewPageAppRunNixOS : Model -> PageApp -> Html Update
viewPageAppRunNixOS model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ] [ text "Run application services in a NixOS VM" ]
        , br [] []
        , bashCodeBlock <|
            String.concat
                [ "nix run "
                , showForgeInputFlakes model
                , "#"
                , pageApp.pageApp_app.app_outputName
                , ".vm"
                ]
        ]


showForgeInputFlakes : Model -> String
showForgeInputFlakes model =
    String.concat
        [ model.model_config.config_repository
        , case commit of
            "master" ->
                ""

            _ ->
                "/" ++ shortCommit
        ]


showForgeInputFlakesLatest : Model -> String
showForgeInputFlakesLatest model =
    String.concat
        [ model.model_config.config_repository
        , "/master"
        ]
