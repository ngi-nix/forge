{
  lib,
  ...
}:
{
  options.build.pythonPackageBuilder = {
    enable = lib.mkEnableOption ''
      Python package builder for reusable Python libraries.

      Uses buildPythonPackage which allows the package to be used as a dependency by other packages'';
    packages = {
      build-system = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "PEP-517 build system dependencies.";
        example = lib.literalExpression "[ pkgs.python3Packages.setuptools pkgs.python3Packages.wheel ]";
      };
      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Native build-time dependencies.

          Use this for tools needed during the build, such as pkg-config or compilers.
        '';
        example = lib.literalExpression "[ pkgs.pkg-config pkgs.cmake ]";
      };
      run = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Native runtime dependencies.

          Use this for non-Python libraries or tools needed at runtime.
        '';
        example = lib.literalExpression "[ pkgs.openssl pkgs.sqlite ]";
      };
      dependencies = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Runtime dependencies (PEP-621).";
        example = lib.literalExpression "[ pkgs.python3Packages.numpy pkgs.python3Packages.attrs ]";
      };
      optional-dependencies = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.package);
        default = { };
        description = ''
          PEP-621 optional dependencies (extras).

          These are additional dependencies that can be installed optionally.
        '';
        example = lib.literalExpression ''
          {
            dev = [ pkgs.python3Packages.pytest ];
            redis = [ pkgs.python3Packages.redis ];
          }
        '';
      };
      check = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Test dependencies.

          Packages needed to run the test suite. When non-empty, tests are
          automatically enabled (doCheck = true).
        '';
        example = lib.literalExpression "[ pkgs.python3Packages.pytestCheckHook ]";
      };
    };
    importsCheck = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of Python modules to verify can be imported after installation.

        This provides a simple smoke test to ensure the package was built correctly.
      '';
      example = [
        "requests"
        "requests.auth"
      ];
    };
    relaxDeps = lib.mkOption {
      type = lib.types.either lib.types.bool (lib.types.listOf lib.types.str);
      default = [ ];
      description = ''
        Remove version constraints from specified dependencies.

        Use when the package requires specific versions but works fine with versions in nixpkgs.
        Set to true to relax all dependencies, or provide a list of dependency names.
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

        Useful for disabling flaky or network-dependent tests.
      '';
      example = [
        "test_network"
        "test_integration"
      ];
    };
  };
}
