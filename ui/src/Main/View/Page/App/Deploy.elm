module Main.View.Page.App.Deploy exposing (..)

import Html exposing (Html, button, div, h5, hr, p, text)
import Html.Attributes exposing (attribute, class, style, tabindex)
import Html.Events exposing (stopPropagationOn)
import Json.Decode as Decode
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Page.App.Run exposing (showForgeInputFlakesLatest)


viewPageAppDeploy : Model -> PageApp -> Html Update
viewPageAppDeploy model pageApp =
    let
        routeApp =
            pageApp.pageApp_route

        onClickRoute =
            Route_App { routeApp | routeApp_deployShown = False }
    in
    if not pageApp.pageApp_route.routeApp_deployShown then
        text ""

    else
        div []
            [ div
                [ class "modal show"
                , style "display" "block"
                , attribute "data-testid" "deploy-modal-container"
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
                                , attribute "data-testid" "close-deploy-modal-button"
                                , onClick (Update_RouteWithoutHistory onClickRoute)
                                ]
                                []
                            ]
                        , div [ class "modal-body" ]
                            [ viewPageAppDeployNixOSModule model pageApp ]
                        ]
                    ]
                ]
            ]


viewPageAppDeployNixOSModule : Model -> PageApp -> Html Update
viewPageAppDeployNixOSModule model pageApp =
    div []
        [ p [ style "margin-bottom" "0em" ] [ text "Create a NixOS system configuration file" ]
        , div
            [ style "max-height" "440px"
            , style "overflow-y" "auto"
            ]
            [ nixCodeBlock <|
                String.join "\n"
                    [ "# flake.nix"
                    , "{"
                    , "  inputs.forge.url = \"" ++ showForgeInputFlakesLatest model ++ "\";"
                    , ""
                    , "  outputs ="
                    , "    inputs@{ self, ... }:"
                    , "    inputs.forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } {"
                    , "      systems = [ \"x86_64-linux\" ];"
                    , "      imports = [ inputs.forge.flakeModules.default ];"
                    , ""
                    , "      # NixOS system configuration"
                    , "      flake.nixosConfigurations." ++ pageApp.pageApp_app.app_name ++ " = inputs.forge.inputs.nixpkgs.lib.nixosSystem {"
                    , "        system = \"x86_64-linux\";"
                    , "        modules = ["
                    , "          # Filesystem and boot configuration"
                    , "          {"
                    , "            fileSystems.\"/\" = {"
                    , "              device = \"/dev/disk/by-label/nixos\";"
                    , "              fsType = \"ext4\";"
                    , "            };"
                    , "            boot.loader.grub.devices = [ \"/dev/sda\" ];"
                    , "          }"
                    , "          # Application module"
                    , "          self.packages.x86_64-linux." ++ pageApp.pageApp_app.app_outputName ++ ".nixosModules.default"
                    , "        ];"
                    , "      };"
                    , ""
                    , "      # Application configuration"
                    , "      perSystem ="
                    , "        { config, pkgs, lib, ... }:"
                    , "        {"
                    , "          forge." ++ pageApp.pageApp_app.app_outputName ++ " = {"
                    , "            # Put custom application configuration here ... "
                    , "            # services.components.<name>.process.environment.VARIABLE = \"value\";"
                    , "          };"
                    , "        };"
                    , "    };"
                    , "}"
                    ]
            ]
        , hr [] []
        , p [ style "margin-bottom" "0em" ] [ text "Check the configuration" ]
        , bashCodeBlock <|
            "nix eval .#nixosConfigurations."
                ++ pageApp.pageApp_app.app_name
                ++ ".config.system.build.toplevel"
        , hr [] []
        , p [ style "margin-bottom" "0em" ] [ text "Test configuration in a VM" ]
        , bashCodeBlock <|
            "nix run .#nixosConfigurations."
                ++ pageApp.pageApp_app.app_name
                ++ ".config.system.build.vm"
        ]
