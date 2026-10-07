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
      default = "";
      description = ''
        Script to test the program runtime.

        Launch tests with:

        ```
        nix build .#apps.<app-name>.test-programs
        ```
      '';
      example = ''
        $program --version
      '';
    };
  };
}
