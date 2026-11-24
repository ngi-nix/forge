{
  getTestOptions,
  config,
  lib,
  pkgs,
  ...
}:

let
  testOptions = (getTestOptions config "app").getSubOptions { };
in

{
  imports = [
    ./nixos.nix
    ./container.nix
  ];

  options = {
    inherit (testOptions)
      nixosConfig
      packages
      sandbox
      broken
      ;

    script = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Script to test application services inside a NixOS machine or container.

        The script runs with `set -euo pipefail`. The `curl_retry` function runs
        `curl --fail` and retries until the service answers.

        Launch tests with:

        ```
        nix build .#apps.<app-name>.test-services-container
        nix build .#apps.<app-name>.test-services-nixos
        ```
      '';
      example = ''
        curl_retry http://localhost:5000 | grep "Hello"
      '';
    };

    scriptWithPreamble = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = ''
        set -euo pipefail

        # Run curl, retrying until the service answers.
        curl_retry() {
          ${lib.getExe pkgs.curl} --fail --silent --show-error \
            --retry 10 --retry-max-time 120 --retry-all-errors "$@"
        }

        ${config.script}
      '';
      description = "The `script` with the shell options and the helper functions.";
    };

    result = {
      # HACK:
      # Prevent toJSON from attempting to convert the `build` options,
      # which won't work because they are whole NixOS test evaluations.
      __toString = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; functionTo str;
        default = self: "nixos-test";
      };
    };
  };
}
