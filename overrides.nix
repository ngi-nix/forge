# This file is empty by default. Use this input to override recipe configuration
# via CLI.
#
# Example:
# nix run --override-input overrides path:./my-overrides.nix -- .#apps.offen.container
#
# my-overrides.nix example:
#
# { lib, ... }:
# {
#   forge.apps.offen.services.components.offen.process = {
#     environment.OFFEN_SERVER_PORT = lib.mkForce "3001";
#     ports = lib.mkForce [ "3001:3001" ];
#   };
# }

{ }
