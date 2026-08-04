{
  lib,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Python application builder for executable Python programs.

      Uses `buildPythonApplication` from Nixpkgs, which builds Python packages
      following PEP-517 (`pyproject.toml`) as standalone applications not
      importable as a dependency by other Python packages.

      For more information, see the
      [Nixpkgs Python documentation](https://nixos.org/manual/nixpkgs/unstable/#python)
    '';
    packages = {
      build-system = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of PEP-517 build system dependencies (e.g. setuptools, hatchling).

          Mapped to `build-system`.
        '';
        example = lib.literalExpression "[ pkgs.python3Packages.setuptools pkgs.python3Packages.wheel ]";
      };
      dependencies = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of Python runtime dependencies required at runtime (PEP-621).

          Mapped to `dependencies`.
        '';
        example = lib.literalExpression "[ pkgs.python3Packages.click pkgs.python3Packages.requests ]";
      };
      optional-dependencies = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.package);
        default = { };
        description = ''
          List of optional Python runtime dependencies grouped by extra name
          (PEP-621 extras).

          Mapped to `optional-dependencies`.
        '';
        example = lib.literalExpression ''
          {
            dev = [ pkgs.python3Packages.pytest ];
            redis = [ pkgs.python3Packages.redis ];
          }
        '';
      };
    };
    importsCheck = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of Python modules to import-check after installation as a smoke
        test.

        Mapped to `pythonImportsCheck`.
      '';
      example = [
        "myapp"
        "myapp.cli"
      ];
    };
    relaxDeps = lib.mkOption {
      type = lib.types.either lib.types.bool (lib.types.listOf lib.types.str);
      default = [ ];
      description = ''
        Remove version constraints from specified dependencies.

        Use when the package specifies strict version bounds that are still
        satisfied by the versions available in Nixpkgs. Set to `true` to relax
        all dependencies, or list specific dependency names.

        Mapped to `pythonRelaxDeps`.
      '';
      example = [
        "click"
        "attrs"
      ];
    };
    disabledTests = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of pytest test names to skip.

        Useful for disabling flaky or network-dependent tests that cannot pass
        in the Nix sandbox.

        Mapped to `disabledTests`.
      '';
      example = [
        "test_network"
        "test_integration"
      ];
    };
  };
}
