module Main.View.Page.App.Deploy exposing (..)

import Html exposing (Html, a, button, div, h4, h5, hr, li, p, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, href, id, style, tabindex, target, title)
import Html.Events exposing (stopPropagationOn)
import Json.Decode as Decode
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Nix exposing (..)
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Route exposing (..)
import Main.Update exposing (..)
import Main.Update.Types exposing (..)
import Main.View.Page.App.Run exposing (showForgeInputFlakesLatest)


nixosInstallerUrl : String
nixosInstallerUrl =
    "https://nixos.org/download/#nixos-iso"


hetznerCloudConsoleUrl : String
hetznerCloudConsoleUrl =
    "https://console.hetzner.cloud/"


hetznerServerImage : String
hetznerServerImage =
    "ubuntu-24.04"


hetznerServerType : String
hetznerServerType =
    "cpx22"


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
                            [ viewPageAppDeployTargets model pageApp
                            , div [ class "tab-content mb-5 p-3 border rounded" ]
                                [ viewPageAppDeployInstructions model pageApp pageApp.pageApp_route.routeApp_deployTarget ]
                            ]
                        ]
                    ]
                ]
            ]


viewPageAppDeployTargets : Model -> PageApp -> Html Update
viewPageAppDeployTargets model pageApp =
    ul [ class "nav nav-pills mb-4" ]
        (listDeployTarget
            |> List.map (viewPageAppDeployTarget model pageApp)
        )


viewPageAppDeployTarget : Model -> PageApp -> DeployTarget -> Html Update
viewPageAppDeployTarget _ pageApp deployTarget =
    li [ class "nav-item" ]
        [ a
            [ classList
                [ ( "nav-link", True )
                , ( "active", deployTarget == pageApp.pageApp_route.routeApp_deployTarget )
                ]
            , style "cursor" "pointer"
            , style "border" "none"
            , attribute "role" "tab"
            , id <| "deploy-" ++ showDeployTargetId deployTarget
            , let
                route =
                    pageApp.pageApp_route
              in
              onClick (Update_RouteWithoutHistory (Route_App { route | routeApp_deployTarget = deployTarget }))
            ]
            [ span [ class "fw-bold" ] [ text <| showDeployTarget deployTarget ]
            ]
        ]


viewPageAppDeployInstructions : Model -> PageApp -> DeployTarget -> Html Update
viewPageAppDeployInstructions model pageApp deployTarget =
    div []
        [ viewPageAppDeploySection "Configuration"
            [ viewPageAppDeployConfiguration model pageApp deployTarget
            , viewPageAppDeployCheck pageApp
            ]
        , viewPageAppDeploySection "Deployment"
            [ viewPageAppDeployEnvironment
            , viewPageAppDeployPreparation pageApp deployTarget
            , viewPageAppDeployNixOSAnywhere pageApp
            ]
        , viewPageAppDeploySection "Update"
            [ viewPageAppDeployUpdate pageApp
            , viewPageAppDeployHardening
            ]
        ]


viewPageAppDeploySection : String -> List (Html Update) -> Html Update
viewPageAppDeploySection sectionTitle steps =
    div [ class "mb-4" ]
        (h4 [ class "fw-bold border-bottom pb-2 mb-3" ] [ text sectionTitle ]
            :: List.intersperse (hr [] []) steps
        )


viewPageAppDeployConfiguration : Model -> PageApp -> DeployTarget -> Html Update
viewPageAppDeployConfiguration model pageApp deployTarget =
    div []
        [ viewPageAppDeployStep "Create a NixOS system configuration in flake.nix file" "configuration"
        , viewPageAppDeployFlake model pageApp deployTarget
        ]


viewPageAppDeployEnvironment : Html Update
viewPageAppDeployEnvironment =
    div []
        [ viewPageAppDeployStep "Launch deployment environment (run all following commands inside it)" "deployment-environment"
        , bashCodeBlock "nix develop"
        ]


viewPageAppDeployPreparation : PageApp -> DeployTarget -> Html Update
viewPageAppDeployPreparation pageApp deployTarget =
    case deployTarget of
        DeployTarget_BareMetal ->
            div []
                [ viewPageAppDeployStep "Prepare a target machine" "bare-metal-preparation"
                , p [ class "mb-1" ]
                    [ text "Boot from the "
                    , a [ href nixosInstallerUrl, target "_blank" ]
                        [ text "NixOS minimal installer" ]
                    , text ", log in and set root password and get machine IP address"
                    ]
                , bashCodeBlock <|
                    String.join "\n"
                        [ "passwd root"
                        , "ip address"
                        ]
                ]

        DeployTarget_Hetzner ->
            div []
                [ viewPageAppDeployStep "Prepare a target machine" "hetzner-cloud-preparation"
                , p [ class "mb-1" ]
                    [ text "Create a server in "
                    , a [ href hetznerCloudConsoleUrl, target "_blank" ]
                        [ text "Hetzner Cloud" ]
                    , text ", and get machine IP address"
                    ]
                , bashCodeBlock "export HCLOUD_TOKEN=<api-token>"
                , bashCodeBlock <|
                    String.join "\n"
                        [ "hcloud server create --name "
                            ++ pageApp.pageApp_app.app_name
                            ++ " --image "
                            ++ hetznerServerImage
                            ++ " --type "
                            ++ hetznerServerType
                            ++ " --ssh-key <key-name>"
                        ]
                ]


viewPageAppDeployCheck : PageApp -> Html Update
viewPageAppDeployCheck pageApp =
    div []
        [ viewPageAppDeployStep "Check the configuration" "test-configuration"
        , bashCodeBlock <|
            "nix eval .#nixosConfigurations."
                ++ pageApp.pageApp_app.app_name
                ++ ".config.system.build.toplevel"
        ]


viewPageAppDeployNixOSAnywhere : PageApp -> Html Update
viewPageAppDeployNixOSAnywhere pageApp =
    div []
        [ viewPageAppDeployStep "Deploy NixOS system" "nixos-deployment"
        , bashCodeBlock <|
            "nixos-anywhere --flake .#"
                ++ pageApp.pageApp_app.app_name
                ++ " --target-host root@<ip-address>"
        , viewPageAppDeployDone pageApp
        ]


viewPageAppDeployDone : PageApp -> Html Update
viewPageAppDeployDone pageApp =
    let
        ports =
            pageApp.pageApp_app.app_services
                |> getAppServicesFirewallPorts
                |> List.map String.fromInt

        portLink portNumber =
            a [ href <| "http://<IP-ADDRESS>:" ++ portNumber, target "_blank" ] [ text portNumber ]
    in
    if List.isEmpty ports then
        text "Deployment is done. Your application is up and running."

    else
        span []
            (text "Deployment is done. Your application is up and running on port(s) "
                :: List.intersperse (text ", ") (List.map portLink ports)
                ++ [ text "." ]
            )


viewPageAppDeployHardening : Html Update
viewPageAppDeployHardening =
    p [ style "margin-bottom" "0em" ]
        [ text "Don't forget to apply additional "
        , a
            [ href "docs/manuals/user/deployment.html#security-hardening"
            , target "_blank"
            ]
            [ text "security hardening" ]
        , text " configuration !"
        ]


viewPageAppDeployUpdate : PageApp -> Html Update
viewPageAppDeployUpdate pageApp =
    div []
        [ viewPageAppDeployStep "Update deployed system after configuration changes" "update"
        , bashCodeBlock <|
            "nixos-rebuild switch --flake .#"
                ++ pageApp.pageApp_app.app_name
                ++ " --target-host root@<ip-address>"
        ]


viewPageAppDeployFlake : Model -> PageApp -> DeployTarget -> Html Update
viewPageAppDeployFlake model pageApp deployTarget =
    let
        flakeHead =
            [ "# flake.nix"
            , "{"
            , "  inputs.forge.url = \"" ++ showForgeInputFlakesLatest model ++ "\";"
            , "  inputs.disko.url = \"github:nix-community/disko\";"
            , "  inputs.disko.inputs.nixpkgs.follows = \"forge/nixpkgs\";"
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
            ]

        flakeTargetModules =
            case deployTarget of
                DeployTarget_BareMetal ->
                    []

                DeployTarget_Hetzner ->
                    [ "          # Hetzner Cloud virtual machine support"
                    , "          (inputs.forge.inputs.nixpkgs + \"/nixos/modules/profiles/qemu-guest.nix\")"
                    ]

        firewallPorts =
            pageApp.pageApp_app.app_services
                |> getAppServicesFirewallPorts
                |> List.map String.fromInt

        devShellTargetPackages =
            case deployTarget of
                DeployTarget_BareMetal ->
                    []

                DeployTarget_Hetzner ->
                    [ "              pkgs.hcloud" ]

        flakeTail =
            [ ""
            , "          # Disk configuration"
            , "          inputs.disko.nixosModules.disko"
            , "          {"
            , "            disko.devices.disk.main = {"
            , "              type = \"disk\";"
            , "              device = \"/dev/sda\";"
            , "              content = {"
            , "                type = \"gpt\";"
            , "                partitions = {"
            , "                  boot = {"
            , "                    size = \"1M\";"
            , "                    type = \"EF02\";"
            , "                  };"
            , "                  ESP = {"
            , "                    size = \"512M\";"
            , "                    type = \"EF00\";"
            , "                    content = {"
            , "                      type = \"filesystem\";"
            , "                      format = \"vfat\";"
            , "                      mountpoint = \"/boot\";"
            , "                      mountOptions = [ \"umask=0077\" ];"
            , "                    };"
            , "                  };"
            , "                  root = {"
            , "                    size = \"100%\";"
            , "                    content = {"
            , "                      type = \"filesystem\";"
            , "                      format = \"ext4\";"
            , "                      mountpoint = \"/\";"
            , "                    };"
            , "                  };"
            , "                };"
            , "              };"
            , "            };"
            , "          }"
            , ""
            , "          # System configuration"
            , "          {"
            , "            # Boot configuration"
            , "            boot.loader.grub = {"
            , "              # support legacy BIOS and UEFI machines"
            , "              efiSupport = true;"
            , "              efiInstallAsRemovable = true;"
            , "            };"
            , ""
            , "            # Remote access (SSH) configuration"
            , "            services.openssh.enable = true;"
            , "            users.users.root.openssh.authorizedKeys.keys = ["
            , "              # TODO: Replace following line with your public SSH key, and remove `throw` line below ..."
            , "              # \"ssh-ed25519 AAAA... user@host\""
            , "              (throw \"SSH key is not set in users.users.root.openssh.authorizedKeys.keys in flake.nix\")"
            , "            ];"
            , ""
            , "            # Firewall configuration"
            , "            networking.firewall.allowedTCPPorts = " ++ String.join " " ("[" :: firewallPorts ++ [ "]" ]) ++ ";"
            , "          }"
            , ""
            , "          # Application module"
            , "          self.packages.x86_64-linux.apps." ++ pageApp.pageApp_app.app_name ++ ".nixosModules.default"
            , "        ];"
            , "      };"
            , ""
            , "      perSystem ="
            , "        { config, pkgs, lib, ... }:"
            , "        {"
            , "          # Application configuration"
            , "          forge.apps." ++ pageApp.pageApp_app.app_name ++ " = {"
            , "            enable = true;"
            , "            # TODO: Set custom application configuration here ... "
            , "            # services.components.<name>.process.environment.VARIABLE = \"value\";"
            , "          };"
            , ""
            , "          # Shell environment"
            , "          devShells.default = pkgs.mkShell {"
            , "            packages = ["
            , "              pkgs.nixos-anywhere"
            , "              pkgs.nixos-rebuild"
            ]

        flakeEnd =
            [ "            ];"
            , "          };"
            , "        };"
            , "    };"
            , "}"
            ]
    in
    div
        [ style "height" "200px"
        , style "min-height" "100px"
        , style "overflow-y" "auto"
        , style "resize" "vertical"
        ]
        [ nixCodeBlock <|
            String.join "\n" (flakeHead ++ flakeTargetModules ++ flakeTail ++ devShellTargetPackages ++ flakeEnd)
        ]


viewPageAppDeployStep : String -> String -> Html Update
viewPageAppDeployStep stepText docsAnchor =
    div [ class "d-flex justify-content-between align-items-center mb-3" ]
        [ p [ style "margin-bottom" "0em" ] [ text stepText ]
        , a
            [ href ("docs/manuals/user/deployment.html#" ++ docsAnchor)
            , class "d-flex align-items-center gap-1 text-decoration-none"
            , target "_blank"
            , title "Deployment Documentation"
            ]
            [ iconBookHalf
            , text "Docs"
            ]
        ]
