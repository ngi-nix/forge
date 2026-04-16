module Main.View.Page.App.Run exposing (..)

import Html exposing (Html, a, br, button, details, div, h5, hr, li, p, small, span, summary, text, ul)
import Html.Attributes exposing (attribute, class, href, id, style, tabindex, target)
import Html.Events exposing (stopPropagationOn)
import Json.Decode as Decode
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route exposing (..)
import Main.Update exposing (..)


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
                    [ class "modal-dialog modal-lg"
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
                , ul
                    [ class "nav nav-underline mb-1"
                    ]
                    (listPreferencesInstall
                        |> List.map (viewPageAppRunNixInstallPreferences model pageApp)
                    )
                , br [] []
                , case appRuntime of
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

                    AppRuntime_VM ->
                        if pageApp.pageApp_app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
                            viewPageAppRunVM model pageApp

                        else
                            text ""
                ]


viewPageAppRunNixInstall : Model -> PageApp -> Html Update
viewPageAppRunNixInstall model pageApp =
    div [ class "accordion" ]
        [ details [ class "accordion-item" ]
            [ summary [ class "accordion-button accordion-header fw-bold" ]
                [ text "Install Nix" ]
            , div [ class "accordion-body" ]
                ([ ul
                    [ class "nav nav-underline mb-1"
                    ]
                    (listPreferencesInstall
                        |> List.map (viewPageAppRunNixInstallPreferences model pageApp)
                    )
                 , br [] []
                 , p [ class "mb-1" ]
                    [ text "1. Install Nix "
                    , a [ href "https://github.com/NixOS/nix-installer#nix-installer", target "_blank" ]
                        [ text "(learn more about this installer)." ]
                    ]
                 , codeBlock <|
                    String.join "\n"
                        [ "curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install" ]
                 , small [ class "mb-1" ]
                    [ text "to uninstall, run:" ]
                 , codeBlock <|
                    "/nix/nix-installer uninstall"
                 ]
                    ++ (case model.model_preferences.preferences_install of
                            PreferencesInstall_NixFlakes ->
                                [ p [ class "mt-3 mb-1" ]
                                    [ text "2. Accept binaries pre-built by Nix Forge (optional, highly recommended) " ]
                                , codeBlock <|
                                    "export NIX_CONFIG=\"accept-flake-config = true\""
                                ]

                            PreferencesInstall_NixTraditional ->
                                [ p [ class "mt-3 mb-1" ]
                                    [ text "2. Configure substitutors (optional, highly recommended)" ]
                                , codeBlock <|
                                    String.join "\n"
                                        [ "export NIX_CONFIG='substituters = https://cache.nixos.org https://ngi-forge.cachix.org"
                                        , "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0='"
                                        ]
                                ]
                       )
                )
            ]
        ]


viewPageAppRunNixInstallPreferences : Model -> PageApp -> PreferencesInstall -> Html Update
viewPageAppRunNixInstallPreferences model _ preferencesInstall =
    let
        preferences =
            model.model_preferences

        isActive =
            model.model_preferences.preferences_install == preferencesInstall

        btnClasses =
            [ "nav-link"
            , if isActive then
                "active"

              else
                ""
            , case preferencesInstall of
                PreferencesInstall_NixFlakes ->
                    "text-primary-emphasis"

                PreferencesInstall_NixTraditional ->
                    "text-secondary-emphasis"
            ]
                |> String.join " "

        badgeClasses =
            if isActive then
                "badge rounded-pill "
                    ++ (case preferencesInstall of
                            PreferencesInstall_NixFlakes ->
                                "text-bg-primary"

                            PreferencesInstall_NixTraditional ->
                                "text-bg-secondary"
                       )

            else
                "d-none"
    in
    li [ class "nav-item" ]
        [ button
            [ class btnClasses
            , style "cursor" "pointer"
            , onClick (Update_SetPreferences { preferences | preferences_install = preferencesInstall })
            ]
            (case preferencesInstall of
                PreferencesInstall_NixFlakes ->
                    [ text "Flakes "
                    , small [ class badgeClasses ] [ text "Recommended" ]
                    ]

                PreferencesInstall_NixTraditional ->
                    [ text "Traditional"
                    ]
            )
        ]


viewPageAppRunShell : Model -> PageApp -> Html Update
viewPageAppRunShell model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ]
            [ text "Enter a shell environment with CLI or GUI programs available" ]
        , br [] []
        , codeBlock <|
            String.concat
                (case model.model_preferences.preferences_install of
                    PreferencesInstall_NixFlakes ->
                        [ "nix shell "
                        , showForgeInputFlakes model
                        , "#"
                        , pageApp.pageApp_app.app_name
                        ]

                    PreferencesInstall_NixTraditional ->
                        [ "nix-shell \\\n"
                        , "  -I forge=\"" ++ showForgeInputTraditional model ++ " \\\n"
                        , "  -p '(import <forge> {})"
                        , "."
                        , pageApp.pageApp_app.app_name
                        , "' "
                        ]
                )
        ]


viewPageAppRunContainer : Model -> PageApp -> Html Update
viewPageAppRunContainer model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ] [ text "Run application services in OCI containers" ]
        , br [] []
        , codeBlock <|
            String.join "\n"
                [ case model.model_preferences.preferences_install of
                    PreferencesInstall_NixFlakes ->
                        String.concat
                            [ "nix build "
                            , showForgeInputFlakes model
                            , "#"
                            , pageApp.pageApp_app.app_name
                            , ".container"
                            ]

                    PreferencesInstall_NixTraditional ->
                        String.concat
                            [ "nix-build \\\n"
                            , "  -I forge=\"" ++ showForgeInputTraditional model ++ " \\\n"
                            , "  -E '(import <forge> {})"
                            , "."
                            , pageApp.pageApp_app.app_name
                            , ".container"
                            , "' "
                            ]
                , ""
                , "./result/bin/build-oci-image"
                , ""
                , "podman load < " ++ pageApp.pageApp_app.app_name ++ ".tar"
                , "podman-compose --profile services --file $(pwd)/result/compose.yaml up"
                ]
        ]


viewPageAppRunVM : Model -> PageApp -> Html Update
viewPageAppRunVM model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ] [ text "Run application services in a NixOS VM" ]
        , br [] []
        , codeBlock <|
            case model.model_preferences.preferences_install of
                PreferencesInstall_NixFlakes ->
                    String.concat
                        [ "nix run "
                        , showForgeInputFlakes model
                        , "#"
                        , pageApp.pageApp_app.app_name
                        , ".vm"
                        ]

                PreferencesInstall_NixTraditional ->
                    String.join "\n"
                        [ String.concat
                            [ "nix-build \\\n"
                            , "  -I forge=\"" ++ showForgeInputTraditional model ++ " \\\n"
                            , "  -E '(import <forge> {})"
                            , "."
                            , pageApp.pageApp_app.app_name
                            , ".vm"
                            , "' "
                            ]
                        , ""
                        , "./result/bin/run-" ++ pageApp.pageApp_app.app_name ++ "-vm"
                        ]
        ]


showForgeInputTraditional : Model -> String
showForgeInputTraditional model =
    String.concat
        [ model.model_config.config_repository |> showNixUrl
        , "/archive/"
        , shortCommit
        , ".tar.gz\""
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
