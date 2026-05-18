{
  lib,

  app,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./nixos.nix
    ./container.nix
  ];

  options = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages required for running tests.";
      example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
    };

    sandbox = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the Nix sandbox when running tests.

        Set to false to allow internet access during tests, which may be
        required when tests need to download additional resources at runtime,
        such as container images pulled by compose files.

        When disabled, tests must be launched with Nix sandbox relaxed.

          - nix build .#<app>.test --option sandbox relaxed --builders ""
          - nix build .#<app>.test-container --option sandbox relaxed --builders ""

        Disable sandbox only when necessary.
      '';
    };

    script = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Bash script to test the application inside a NixOS machine or container.

        Launch test:
          - nix build .#<app>.test
          - nix build .#<app>.test-container
      '';
      example = lib.literalExpression ''
        '''
        curl -f http://localhost:8000 | grep "Hello"
        '''
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
