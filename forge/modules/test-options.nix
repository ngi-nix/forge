# module that contains common test options

{ config, type }:

{
  lib,
  ...
}:

assert lib.elem type [
  "app"
  "pkg"
];

let
  isApp = type == "app";
  isPkg = type == "pkg";
in

{
  options = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of packages available in the test script.";
      example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
    };

    runner = lib.mkOption {
      type = lib.types.enum [
        "bash"
        "nixos"
      ];
      default = "bash";
      description = ''
        Type of runner to execute the script.

        When using the `nixos` VM runner, you can pass extra configurations
        using the `test.nixosModules` option.
      '';
    };

    nixosConfig = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = ''
        Extra configuration passed to the NixOS VM running the test.

        See the list of available
        [NixOS options](https://search.nixos.org/options) .
      '';
      example = lib.literalExpression ''
        {
          virtualisation.memorySize = 4096;
          virtualisation.diskSize = 10240;
        }
      '';
    };

    sandbox = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the Nix sandbox when running tests through the `nixos` runner.

        Set to _false_ to allow internet access during tests, which may be
        required when tests need to download additional resources 
        at runtime${lib.optionalString isApp ", such as container images pulled by compose files"}.

        When disabled, tests must be launched with Nix sandbox set to relaxed
        using the following command(s):

      ''
      + lib.optionalString isApp ''
        ```
        nix build .#apps.<app-name>.test-services-nixos --option sandbox relaxed --builders ""
        nix build .#apps.<app-name>.test-services-container --option sandbox relaxed --builders ""
        ```
      ''
      + lib.optionalString isPkg ''
        ```
        nix build .#pkgs.<app-name>.test --option sandbox relaxed --builders ""
        ```
      ''
      + ''

        Disabling sandbox can cause problems with test reproducibility.
        Use only when necessary.
      '';
    };

    derivation = lib.mkOption {
      internal = true;
      description = "Function that builds the test derivation according to runner.";
      type = lib.types.functionTo lib.types.package;
      default =
        {
          pkgs,
          ...
        }@args:
        let
          name = "${args.finalApp.name or args.finalAttrs.pname}-test";
          packages = [ (args.finalApp or args.finalAttrs.finalPackage) ] ++ config.packages;
        in
        if config.runner == "bash" then
          pkgs.testers.runCommand {
            inherit name;
            buildInputs = packages;
            script = config.script + "\ntouch $out";
          }
        else if config.runner == "nixos" then
          (pkgs.testers.runNixOSTest {
            inherit name;
            nodes.machine = {
              imports = [ config.nixosConfig ];
              environment.systemPackages = packages;
              system.stateVersion = "25.11";
            };
            testScript = ''
              machine.start()
              machine.wait_for_unit("multi-user.target")
              machine.succeed("${pkgs.writeShellScript name ''
                set -euo pipefail
                ${config.script}
              ''}")
            '';
          }).overrideTestDerivation
            (_: lib.optionalAttrs (!config.sandbox) { __noChroot = true; })
        else
          throw "Unsupported test runner: ${config.runner}";
    };
  };
}
