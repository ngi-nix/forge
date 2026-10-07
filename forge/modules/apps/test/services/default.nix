{
  getTestOptions,
  config,
  lib,
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
      ;

    script = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Script to test application services inside a NixOS machine or container.

        Launch tests with:

        ```
        nix build .#apps.<app-name>.test-services-container
        nix build .#apps.<app-name>.test-services-nixos
        ```
      '';
      example = ''
        curl --fail http://localhost:5000 | grep "Hello"
      '';
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
