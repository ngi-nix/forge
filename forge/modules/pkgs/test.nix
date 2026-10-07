{
  getTestOptions,
  config,
  lib,
  ...
}:

let
  testOptions = (getTestOptions config "pkg").getSubOptions { };
in

{
  options = {
    inherit (testOptions)
      nixosConfig
      packages
      runner
      sandbox
      derivation
      ;

    script = lib.mkOption {
      type = lib.types.str;
      default = ''
        echo "Test script"
      '';
      description = ''
        Script to test the package.
        The package being tested is available in PATH.

        Launch test with:

        ```
        nix build .#pkgs.''${package}.test
        ```
      '';
      example = ''
        hello | grep "Hello, world"
      '';
    };
  };
}
