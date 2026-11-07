module Main.View.Page.App.Run exposing (..)

import Dict
import Html exposing (Html, a, br, button, code, details, div, h5, h6, hr, li, p, small, span, summary, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (attribute, class, href, id, style, tabindex, target, title)
import Html.Events exposing (stopPropagationOn)
import Json.Decode as Decode
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Helpers.String exposing (shellQuote)
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


appRunContainerCommand : Model -> PageApp -> String
appRunContainerCommand model pageApp =
    String.concat
        [ "nix run "
        , showForgeInputFlakes model
        , "#"
        , pageApp.pageApp_app.app_outputName
        , ".container"
        ]


viewPageAppRunContainer : Model -> PageApp -> Html Update
viewPageAppRunContainer model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ] [ text "Run application services in OCI containers" ]
        , br [] []
        , bashCodeBlock (appRunContainerCommand model pageApp)
        , viewPageAppRunContainerConfigure model pageApp
        , hr [] []
        , viewPageAppRunContainerBuildOCI model pageApp
        ]


viewPageAppRunContainerConfigure : Model -> PageApp -> Html Update
viewPageAppRunContainerConfigure model pageApp =
    case appConfigurableComponents pageApp.pageApp_app of
        [] ->
            text ""

        components ->
            div [ attribute "data-testid" "run-container-configure" ]
                [ hr [] []
                , details []
                    (summary [] [ text "Configure services" ]
                        :: br [] []
                        :: List.concatMap (viewPageAppRunContainerConfigureComponent model pageApp) components
                    )
                ]


viewPageAppRunContainerConfigureComponent : Model -> PageApp -> ( String, AppComponent ) -> List (Html Update)
viewPageAppRunContainerConfigureComponent model pageApp ( name, component ) =
    let
        parameters =
            Dict.toList component.appComponent_parameters

        configFiles =
            component.appComponent_configFiles

        run =
            appRunContainerCommand model pageApp

        image =
            appImageReference pageApp.pageApp_app name

        assignment ( variable, parameter ) =
            variable ++ "=" ++ shellQuote (Maybe.withDefault "value" parameter.appParameter_default)

        environmentOptions =
            List.map (\parameter -> "-e " ++ assignment parameter) parameters

        volumeOptions =
            List.map (\path -> "-v " ++ shellQuote ("./" ++ path ++ ":/config/" ++ path ++ ":ro,z")) configFiles
    in
    [ h6 [] [ text name ]
    , if List.isEmpty parameters then
        text ""

      else
        div []
            [ p [ class "mb-1" ] [ text "Set parameters with environment variables:" ]
            , table [ class "table table-sm" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Variable" ]
                        , th [] [ text "Default" ]
                        , th [] [ text "Description" ]
                        ]
                    ]
                , tbody [] (List.map viewPageAppRunContainerParameter parameters)
                ]
            , bashCodeBlock (String.join " " ([ "podman run" ] ++ environmentOptions ++ [ image ]))
            ]
    , if List.isEmpty configFiles then
        text ""

      else
        div []
            [ p [ class "mb-1" ] [ text "Replace a configuration file with a mount at /config. Add arguments for the service after the image name:" ]
            , ul [] (List.map (\path -> li [] [ code [] [ text path ] ]) configFiles)
            , bashCodeBlock (String.join " " ([ "podman run" ] ++ volumeOptions ++ [ image ]))
            ]
    , case appComponentReferences component of
        [] ->
            text ""

        references ->
            div []
                [ p [ class "mb-1" ] [ text "Upstream references:" ]
                , ul []
                    (List.map
                        (\( title_, link ) -> li [] [ a [ href link, target "_blank" ] [ text title_ ] ])
                        references
                    )
                ]
    , if List.isEmpty parameters && List.isEmpty configFiles then
        text ""

      else
        details []
            [ summary [] [ text "Configure with Nix" ]
            , br [] []
            , if List.isEmpty parameters then
                text ""

              else
                bashCodeBlock (String.join " " (List.map assignment parameters ++ [ run ]))
            , if List.isEmpty configFiles then
                text ""

              else
                div []
                    [ p [ class "mb-1" ]
                        [ text "Replace configuration files with files in "
                        , code [] [ text ("$FORGE_CONFIG_DIR/" ++ name) ]
                        , text ":"
                        ]
                    , bashCodeBlock ("FORGE_CONFIG_DIR=./config " ++ run)
                    ]
            ]
    ]


{-| Reference of the image of a service component.
-}
appImageReference : App -> String -> String
appImageReference app name =
    "localhost/" ++ app.app_name ++ "-" ++ name ++ ":latest"


viewPageAppRunContainerParameter : ( String, AppParameter ) -> Html Update
viewPageAppRunContainerParameter ( variable, parameter ) =
    tr []
        [ td [] [ code [] [ text variable ] ]
        , td [] [ code [] [ text (Maybe.withDefault "" parameter.appParameter_default) ] ]
        , td []
            [ text
                (String.join " "
                    (parameter.appParameter_description
                        :: (parameter.appParameter_enum
                                |> Maybe.map (\values -> [ "One of: " ++ String.join ", " values ++ "." ])
                                |> Maybe.withDefault []
                           )
                    )
                )
            ]
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
