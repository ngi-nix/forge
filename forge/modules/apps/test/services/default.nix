{
  lib,
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
      description = "List of packages available in the test script.";
      example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
    };

    sandbox = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the Nix sandbox when running tests.

        Set to _false_ to allow internet access during tests, which may be
        required when tests need to download additional resources at runtime,
        such as container images pulled by compose files.

        When disabled, tests must be launched with Nix sandbox set to relaxed
        using following commands:

        ```
        nix build .#<app>.test-services-nixos --option sandbox relaxed --builders ""
        nix build .#<app>.test-services-container --option sandbox relaxed --builders ""
        ```

        Disabling sandbox can cause problems with test reproducibility.
        Use only when necessary.
      '';
    };

    script = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Script to test application services inside a NixOS machine or container.

        Launch tests with:

        ```
        nix build .#<app>.test-services-container
        nix build .#<app>.test-services-nixos
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
