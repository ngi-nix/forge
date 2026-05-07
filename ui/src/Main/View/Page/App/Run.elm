module Main.View.Page.App.Run exposing (..)

import Html exposing (Html, a, br, button, details, div, h5, hr, li, p, small, span, summary, text, ul)
import Html.Attributes exposing (attribute, class, href, id, style, tabindex, target)
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
                            , div [ class "tab-content mb-5 p-3 border rounded", style "border-color" "#2579ab !important" ]
                                [ viewPageAppRunInstructions model pageApp ]
                            ]
                        ]
                    ]
                ]
            ]


viewPageAppRunRuntimes : Model -> PageApp -> Html Update
viewPageAppRunRuntimes model pageApp =
    ul [ class "nav nav-pills mb-3" ]
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
                    [ class "nav nav-underline mb-2"
                    ]
                    (listPreferencesInstall
                        |> List.map (viewPageAppRunNixInstallPreferences model pageApp)
                    )
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

                    AppRuntime_NixOS ->
                        if pageApp.pageApp_app.app_services.appServices_runtimes.appServicesRuntimes_nixos.enable then
                            viewPageAppRunNixOS model pageApp

                        else
                            text ""
                ]


viewPageAppRunNixInstall : Model -> PageApp -> Html Update
viewPageAppRunNixInstall model pageApp =
    div [ class "accordion mb-3" ]
        [ details [ class "accordion-item" ]
            [ summary [ class "accordion-button accordion-header fw-bold" ]
                [ text "Install Nix" ]
            , div [ class "accordion-body" ]
                [ ul
                    [ class "nav nav-underline mb-3"
                    ]
                    (listPreferencesInstall
                        |> List.map (viewPageAppRunNixInstallPreferences model pageApp)
                    )
                , p [ class "mb-1" ]
                    [ text "1. Install Nix "
                    , a [ href "https://github.com/NixOS/nix-installer#nix-installer", target "_blank" ]
                        [ text "(learn more about this installer)." ]
                    ]
                , case model.model_preferences.preferences_install of
                    PreferencesInstall_NixFlakes ->
                        codeBlock <|
                            String.join "\n"
                                [ "curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes" ]

                    PreferencesInstall_NixTraditional ->
                        codeBlock <|
                            String.join "\n"
                                [ "curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install" ]
                , small [ class "mb-1" ]
                    [ text "to uninstall, run:" ]
                , codeBlock <|
                    "/nix/nix-installer uninstall"
                , case model.model_preferences.preferences_install of
                    PreferencesInstall_NixFlakes ->
                        div []
                            [ p [ class "mt-3 mb-1" ]
                                [ text "2. Accept binaries pre-built by NGI Forge (optional, highly recommended) " ]
                            , codeBlock <|
                                "export NIX_CONFIG=\"accept-flake-config = true\""
                            ]

                    PreferencesInstall_NixTraditional ->
                        div []
                            [ p [ class "mt-3 mb-1" ]
                                [ text "2. Configure substitutors (optional, highly recommended)" ]
                            , codeBlock <|
                                String.join "\n"
                                    [ "export NIX_CONFIG='substituters = https://cache.nixos.org https://ngi-forge.cachix.org"
                                    , "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0='"
                                    ]
                            ]
                ]
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
            "badge rounded-pill "
                ++ (case preferencesInstall of
                        PreferencesInstall_NixFlakes ->
                            "text-bg-primary"

                        PreferencesInstall_NixTraditional ->
                            "text-bg-secondary"
                   )
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


plainContainer : Html Update -> Html Update
plainContainer content =
    div [ class "pst-tab-content-container" ]
        [ content ]


tabbedContainer : Model -> PageApp -> Html Update -> Html Update
tabbedContainer model pageApp content =
    div [ class "mb-3" ]
        [ ul [ class "pst-tab-set" ]
            (listPreferencesContainer
                |> List.map (viewPageAppRunContainerPreferences model pageApp)
            )
        , div [ class "pst-tab-content-container" ]
            [ content ]
        ]


viewPageAppRunContainerPreferences : Model -> PageApp -> PreferencesContainer -> Html Update
viewPageAppRunContainerPreferences model _ preferencesContainer =
    let
        preferences =
            model.model_preferences

        isActive =
            model.model_preferences.preferences_container == preferencesContainer

        labelClasses =
            [ "pst-tab-label"
            , if isActive then
                "active"

              else
                ""
            ]
                |> String.join " "
    in
    li [ class "pst-tab-item" ]
        [ button
            [ class labelClasses
            , style "cursor" "pointer"
            , onClick (Update_SetPreferences { preferences | preferences_container = preferencesContainer })
            ]
            (case preferencesContainer of
                PreferencesContainer_Podman ->
                    [ text "podman"
                    ]

                PreferencesContainer_Docker ->
                    [ text "docker"
                    ]
            )
        ]


viewPageAppRunShell : Model -> PageApp -> Html Update
viewPageAppRunShell model pageApp =
    div [ class "accordion pst-colorless" ]
        [ details [ class "accordion-item", attribute "open" "" ]
            [ summary [ class "accordion-button accordion-header" ]
                [ text "Enter a shell environment with CLI or GUI programs available" ]
            , div [ class "accordion-body" ]
                [ plainContainer <|
                    codeBlock <|
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
            ]
        ]


viewPageAppRunContainer : Model -> PageApp -> Html Update
viewPageAppRunContainer model pageApp =
    let
        ( runScript, composeSuffix ) =
            case model.model_preferences.preferences_container of
                PreferencesContainer_Podman ->
                    ( "./result/bin/run-podman", ".run-podman-compose" )

                PreferencesContainer_Docker ->
                    ( "./result/bin/run-docker", ".run-docker-compose" )

        composeScript =
            "./result/bin/" ++ String.dropLeft 1 composeSuffix
    in
    div []
        [ div [ class "accordion pst-colorless" ]
            [ details [ class "accordion-item", attribute "open" "" ]
                [ summary [ class "accordion-button accordion-header" ]
                    [ text "Run application services in OCI containers" ]
                , div [ class "accordion-body" ]
                    [ plainContainer <|
                        codeBlock <|
                            String.join "\n"
                                [ case model.model_preferences.preferences_install of
                                    PreferencesInstall_NixFlakes ->
                                        String.concat
                                            [ "nix build "
                                            , showForgeInputFlakes model
                                            , "#"
                                            , pageApp.pageApp_app.app_name
                                            , ".container"
                                            , "\n\n"
                                            , "./result/bin/run-container"
                                            ]

                                    PreferencesInstall_NixTraditional ->
                                        String.concat
                                            [ "nix-build \\\n"
                                            , "  -I forge=\"" ++ showForgeInputTraditional model ++ " \\\n"
                                            , "  -E '(import <forge> {})." ++ pageApp.pageApp_app.app_name ++ ".container'"
                                            , "\n\n"
                                            , "./result/bin/run-container"
                                            ]
                                ]
                    ]
                ]
            ]
        , viewPageAppRunContainerBuildOCI model pageApp
        , div [ class "accordion pst-colorless mt-3" ]
            [ details [ class "accordion-item" ]
                [ summary [ class "accordion-button accordion-header" ] [ text "Advanced & Administration" ]
                , div [ class "accordion-body" ]
                    [ p [ class "mb-1" ] [ text "Use these helper scripts to manage the running application (logs, exec, stop, etc.):" ]
                    , tabbedContainer model pageApp <|
                        codeBlock <|
                            String.join "\n"
                                [ "# View logs"
                                , composeScript ++ " logs -f"
                                , ""
                                , "# Enter container"
                                , composeScript ++ " exec " ++ pageApp.pageApp_app.app_name ++ " bash"
                                ]
                    , p [ class "mt-3 mb-1" ] [ text "To explicitly use a specific oci engine:" ]
                    , tabbedContainer model pageApp <|
                        codeBlock <|
                            runScript
                    ]
                ]
            ]
        ]


viewPageAppRunContainerBuildOCI : Model -> PageApp -> Html Update
viewPageAppRunContainerBuildOCI model pageApp =
    div [ class "accordion pst-colorless mt-3" ]
        [ details [ class "accordion-item" ]
            [ summary [ class "accordion-button accordion-header" ] [ text "Build container image manually" ]
            , div [ class "accordion-body" ]
                [ tabbedContainer model pageApp <|
                    codeBlock <|
                        case model.model_preferences.preferences_install of
                            PreferencesInstall_NixFlakes ->
                                String.join "\n"
                                    [ String.concat
                                        [ "nix build "
                                        , showForgeInputFlakes model
                                        , "#"
                                        , pageApp.pageApp_app.app_name
                                        , ".container"
                                        ]
                                    , ""
                                    , "./result/bin/build-oci-image"
                                    ]

                            PreferencesInstall_NixTraditional ->
                                String.concat
                                    [ "nix-build \\\n"
                                    , "  -I forge=\"" ++ showForgeInputTraditional model ++ " \\\n"
                                    , "  -E '(import <forge> {})." ++ pageApp.pageApp_app.app_name ++ ".container'"
                                    , "\n\n"
                                    , "./result/bin/build-oci-image"
                                    ]
                ]
            ]
        ]


viewPageAppRunNixOS : Model -> PageApp -> Html Update
viewPageAppRunNixOS model pageApp =
    div [ class "accordion pst-colorless" ]
        [ details [ class "accordion-item", attribute "open" "" ]
            [ summary [ class "accordion-button accordion-header" ]
                [ text "Run application services in a NixOS VM" ]
            , div [ class "accordion-body" ]
                [ plainContainer <|
                    codeBlock <|
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
