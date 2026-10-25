module Main.View.Page.App.Run exposing (..)

import Html exposing (Html, a, br, button, details, div, h5, hr, input, label, li, p, pre, small, span, summary, text, textarea, ul)
import Html.Attributes exposing (attribute, class, for, href, id, rel, rows, spellcheck, style, tabindex, target, title, type_, value)
import Html.Events exposing (onInput, stopPropagationOn)
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
import Url.Builder


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

            Just AppRuntime_Browser ->
                -- The browser runtime does not need Nix.
                [ div [ class "d-flex justify-content-end align-items-center mb-2" ]
                    [ viewPageAppRunDocs AppRuntime_Browser ]
                , if pageApp.pageApp_app.app_programs.appPrograms_runtimes.appProgramsRuntimes_browser.enable then
                    viewPageAppRunBrowser model pageApp

                  else
                    text ""
                ]

            Just appRuntime ->
                [ viewPageAppRunNixInstall model pageApp
                , hr [] []
                , div [ class "d-flex justify-content-end align-items-center mb-2" ]
                    [ viewPageAppRunDocs appRuntime
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

                    AppRuntime_Browser ->
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


viewPageAppRunDocs : AppRuntime -> Html Update
viewPageAppRunDocs appRuntime =
    a
        [ href ("docs/manuals/contributor/how_to/app_recipe.html#" ++ (showAppRuntime appRuntime |> String.toLower) ++ "-runtime")
        , class "d-flex align-items-center gap-1 text-decoration-none"
        , target "_blank"
        , title "Runtime Documentation"
        ]
        [ iconBookHalf
        , text "Docs"
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


viewPageAppRunBrowser : Model -> PageApp -> Html Update
viewPageAppRunBrowser model pageApp =
    let
        app =
            pageApp.pageApp_app

        browser =
            app.app_programs.appPrograms_runtimes.appProgramsRuntimes_browser
    in
    div []
        [ if String.isEmpty browser.wasmProgram then
            text ""

          else
            viewPageAppRunBrowserWasm model app browser.wasmProgram
        , p [ class "mb-1" ]
            [ text
                (if String.isEmpty browser.wasmProgram then
                    "Run the CLI programs in a Linux virtual machine in the web browser."

                 else
                    "Or run the CLI programs in a Linux virtual machine in the web browser."
                )
            ]
        , p [ class "mb-0" ]
            [ a
                [ href (trynixUrl app)
                , target "_blank"
                , rel "noopener"
                , class "btn btn-outline-primary btn-sm"
                , attribute "data-testid" "run-browser-vm"
                ]
                [ text "Open in trynix.dev" ]
            , small [ class "text-body-secondary ms-2" ]
                [ text "The virtual machine downloads approximately 30 MB and has no network." ]
            ]
        ]


viewPageAppRunBrowserWasm : Model -> App -> String -> Html Update
viewPageAppRunBrowserWasm model app wasmProgram =
    let
        run =
            getBrowserRun model app

        running =
            run.browserRun_status == BrowserRunStatus_Running

        argsId =
            "run-browser-args"

        stdinId =
            "run-browser-stdin"
    in
    div [ class "mb-3" ]
        [ p [ class "mb-1" ]
            [ text "Run the WebAssembly build of the program in this web browser." ]
        , label [ for argsId, class "form-label small mb-0" ] [ text "Arguments" ]
        , div [ class "input-group input-group-sm mb-2" ]
            [ span [ class "input-group-text font-monospace" ] [ text wasmProgram ]
            , input
                [ id argsId
                , type_ "text"
                , class "form-control font-monospace"
                , spellcheck False
                , value run.browserRun_args
                , onInput (Update_BrowserRunArgs app)
                , attribute "data-testid" "run-browser-args"
                ]
                []
            ]
        , label [ for stdinId, class "form-label small mb-0" ] [ text "Standard input" ]
        , textarea
            [ id stdinId
            , class "form-control form-control-sm font-monospace mb-2"
            , rows 4
            , spellcheck False
            , value run.browserRun_stdin
            , onInput (Update_BrowserRunStdin app)
            , attribute "data-testid" "run-browser-stdin"
            ]
            []
        , if running then
            button
                [ type_ "button"
                , class "btn btn-outline-danger btn-sm"
                , onClick Update_BrowserRunStop
                , attribute "data-testid" "run-browser-stop"
                ]
                [ text "Stop" ]

          else
            button
                [ type_ "button"
                , class "btn btn-primary btn-sm"
                , onClick (Update_BrowserRunStart app)
                , attribute "data-testid" "run-browser-start"
                ]
                [ text "Run" ]
        , viewPageAppRunBrowserOutput run
        ]


viewPageAppRunBrowserOutput : BrowserRun -> Html Update
viewPageAppRunBrowserOutput run =
    let
        status =
            case run.browserRun_status of
                BrowserRunStatus_Idle ->
                    []

                BrowserRunStatus_Running ->
                    [ small [ class "text-body-secondary" ] [ text "Running..." ] ]

                BrowserRunStatus_Exited code ->
                    [ small
                        [ class
                            (if code == 0 then
                                "text-body-secondary"

                             else
                                "text-danger"
                            )
                        ]
                        [ text ("Exit code " ++ String.fromInt code) ]
                    ]

                BrowserRunStatus_Failed error ->
                    [ small [ class "text-danger" ] [ text error ] ]
    in
    if run.browserRun_status == BrowserRunStatus_Idle then
        text ""

    else
        div [ class "mt-2", attribute "data-testid" "run-browser-output" ]
            (pre [ class "bg-body-tertiary border rounded p-2 mb-1", style "max-height" "20em" ]
                (run.browserRun_output
                    |> List.reverse
                    |> List.map
                        (\( stream, chunk ) ->
                            case stream of
                                BrowserRunStream_Stdout ->
                                    text chunk

                                BrowserRunStream_Stderr ->
                                    span [ class "text-danger" ] [ text chunk ]
                        )
                )
                :: status
            )


{-| URL of trynix.dev that boots a Linux virtual machine
with the packages of `app` from the binary cache of the Forge.
-}
trynixUrl : App -> String
trynixUrl app =
    Url.Builder.crossOrigin "https://trynix.dev"
        []
        (List.filterMap (.drv_outPath >> Maybe.map (Url.Builder.string "path")) app.app_programs.appPrograms_packages
            ++ [ Url.Builder.string "cache" "https://ngi-forge.cachix.org ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0=" ]
        )


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


{-| Flake reference of the Forge repository.

When the UI is served from localhost (eg. by the development server),
the commands are run from the local repository checkout.

-}
showForgeInputFlakes : Model -> String
showForgeInputFlakes model =
    if model.model_isLocalhost then
        "."

    else
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
