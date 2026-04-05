module Main.View.Instructions exposing (..)

import Html exposing (Html, a, br, button, details, div, h4, hr, li, p, small, summary, text, ul)
import Html.Attributes exposing (class, href, id, style, target)
import Main.Config exposing (commit, shortCommit)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Markdown as Markdown
import Main.Helpers.Nix exposing (..)
import Main.Model exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route exposing (..)
import Main.Update exposing (..)


viewInstructionsUsage : Model -> PageApp -> Html Update
viewInstructionsUsage _ pageApp =
    if not (String.isEmpty pageApp.pageApp_app.app_usage) then
        div [ id "usage", class "mt-4" ]
            [ hr [] []
            , h4 [ class "mb-3" ] [ text "Usage Instructions" ]
            , div [ class "markdown-content" ]
                (pageApp.pageApp_app.app_usage
                    |> Markdown.render
                )
            ]

    else
        text ""


viewInstructionsNixInstall : Model -> PageApp -> Html Update
viewInstructionsNixInstall model pageApp =
    div [ class "accordion" ]
        [ details [ class "accordion-item" ]
            [ summary [ class "accordion-button accordion-header fw-bold" ]
                [ text "Install Nix" ]
            , div [ class "accordion-body" ]
                ([ ul
                    [ class "nav nav-underline mb-1"
                    ]
                    (listPreferencesInstall
                        |> List.map (viewPreferencesInstall model pageApp)
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
                                        [ "export NIX_CONFIG='substituters = https://cache.nixos.org/ https://ngi.cachix.org/"
                                        , "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ngi.cachix.org-1:n+CAL72ROC3qQuLxIHpV+Tw5t42WhXmMhprAGkRSrOw='"
                                        ]
                                ]
                       )
                )
            ]
        ]


viewPageAppInstructions : Model -> PageApp -> Html Update
viewPageAppInstructions model pageApp =
    let
        instructions =
            case pageApp.pageApp_route.routeApp_runRuntime of
                Nothing ->
                    text "There is no such runtime for this application"

                Just appRuntime ->
                    div []
                        [ case appRuntime of
                            AppRuntime_Shell ->
                                if pageApp.pageApp_app.app_programs.enable then
                                    viewProgramsInstructions model pageApp

                                else
                                    text ""

                            AppRuntime_Container ->
                                if pageApp.pageApp_app.app_container.enable then
                                    viewContainerInstructions model pageApp

                                else
                                    text ""

                            AppRuntime_VM ->
                                if pageApp.pageApp_app.app_vm.enable then
                                    viewVMInstructions model pageApp

                                else
                                    text ""
                        ]
    in
    div []
        [ if pageApp.pageApp_app |> listAppRuntimeAvailable |> List.isEmpty then
            div []
                [ p [ class "text-danger" ] [ text "No runtime is enabled for this app." ]
                , p [] [ text "Enable at least one of the - programs, container or nixos vm - in recipe file." ]
                ]

          else
            div []
                [ viewInstructionsNixInstall model pageApp
                , hr [] []
                , ul
                    [ class "nav nav-underline mb-1"
                    ]
                    (listPreferencesInstall
                        |> List.map (viewPreferencesInstall model pageApp)
                    )
                , br [] []
                , instructions
                ]
        ]


viewPreferencesInstall : Model -> PageApp -> PreferencesInstall -> Html Update
viewPreferencesInstall model pageApp preferencesInstall =
    let
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
            , onClick (Update_SavePreferences preferencesInstall)
            ]
            [ text
                (case preferencesInstall of
                    PreferencesInstall_NixFlakes ->
                        "Flakes "

                    PreferencesInstall_NixTraditional ->
                        "Traditional "
                )
            , small [ class badgeClasses ]
                [ text
                    (case preferencesInstall of
                        PreferencesInstall_NixFlakes ->
                            "Recommended"

                        PreferencesInstall_NixTraditional ->
                            "Classic"
                    )
                ]
            ]
        ]


nixShellForgeInput : Model -> String
nixShellForgeInput model =
    "  -I forge=\"" ++ (model.model_config.config_repository |> showNixUrl) ++ "/archive/" ++ shortCommit ++ ".tar.gz\" \\\n"


nixFlakeForgeInput : Model -> String
nixFlakeForgeInput model =
    String.concat
        [ model.model_config.config_repository
        , if commit /= "master" then
            "/" ++ shortCommit

          else
            ""
        ]


viewProgramsInstructions : Model -> PageApp -> Html Update
viewProgramsInstructions model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ]
            [ text "Enter a shell environment with CLI or GUI programs available" ]
        , br [] []
        , codeBlock <|
            String.concat
                (case model.model_preferences.preferences_install of
                    PreferencesInstall_NixFlakes ->
                        [ "nix shell "
                        , nixFlakeForgeInput model
                        , "#"
                        , pageApp.pageApp_app |> app_output
                        ]

                    PreferencesInstall_NixTraditional ->
                        [ "nix-shell \\\n"
                        , nixShellForgeInput model
                        , "  -p '(import <forge> {})"
                        , "."
                        , pageApp.pageApp_app |> app_output
                        , "' "
                        ]
                )
        ]


viewContainerInstructions : Model -> PageApp -> Html Update
viewContainerInstructions model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ] [ text "Run application services in OCI containers" ]
        , br [] []
        , codeBlock <|
            String.join "\n"
                [ case model.model_preferences.preferences_install of
                    PreferencesInstall_NixFlakes ->
                        String.concat
                            [ "nix build "
                            , nixFlakeForgeInput model
                            , "#"
                            , pageApp.pageApp_app |> app_output
                            , ".container"
                            ]

                    PreferencesInstall_NixTraditional ->
                        String.concat
                            [ "nix-build \\\n"
                            , nixShellForgeInput model
                            , "  -E '(import <forge> {})"
                            , "."
                            , pageApp.pageApp_app |> app_output
                            , ".container"
                            , "' "
                            ]
                , ""
                , "./result/bin/build-oci"
                , ""
                , "podman load < " ++ (pageApp.pageApp_app |> app_output) ++ ".tar"
                , "podman-compose --profile services --file $(pwd)/result/compose.yaml up"
                ]
        ]


viewVMInstructions : Model -> PageApp -> Html Update
viewVMInstructions model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ] [ text "Run application services in a NixOS VM" ]
        , br [] []
        , codeBlock <|
            case model.model_preferences.preferences_install of
                PreferencesInstall_NixFlakes ->
                    String.concat
                        [ "nix run "
                        , nixFlakeForgeInput model
                        , "#"
                        , pageApp.pageApp_app |> app_output
                        , ".vm"
                        ]

                PreferencesInstall_NixTraditional ->
                    String.join "\n"
                        [ String.concat
                            [ "nix-build \\\n"
                            , nixShellForgeInput model
                            , "  -E '(import <forge> {})"
                            , "."
                            , pageApp.pageApp_app |> app_output
                            , ".vm"
                            , "' "
                            ]
                        , ""
                        , "./result/bin/run-" ++ pageApp.pageApp_app.app_name ++ "-vm"
                        ]
        ]
