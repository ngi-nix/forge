# Swap this file at the CLI to override recipe configuration without editing
# recipes:
#
# Example:
# nix run --override-input overrides path:./my-overrides.nix -- .#apps.offen.container
#
# my-overrides.nix:
#
#   { lib, ... }:
#   {
#     forge.apps.offen.services.components.offen.process = {
#       environment.OFFEN_SERVER_PORT = lib.mkForce "3001";
#       ports = lib.mkForce [ "3001:3001" ];
#     };
#   }
{
}
