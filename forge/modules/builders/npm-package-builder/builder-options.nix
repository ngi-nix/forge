{
  lib,
  ...
}:
{
  options.build.npmPackageBuilder = {
    enable = lib.mkEnableOption ''
      NPM package builder for JavaScript/TypeScript packages.

      Uses buildNpmPackage'';

    packages = {
      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Build-time dependencies (native architecture).

          Tools needed during compilation that run on the build machine.
        '';
        example = lib.literalExpression "[ pkgs.nodejs ]";
      };
      run = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Runtime dependencies (target architecture).

          Libraries needed by the package at runtime.
        '';
        example = lib.literalExpression "[ pkgs.vips ]";
      };
      check = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Test dependencies.

          Packages needed to run tests.
        '';
      };
    };

    npmDepsHash = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        SHA256 hash of the package-lock.json file or source.

        Leave empty initially - nix will provide the correct hash on first build.
      '';
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    npmInstallFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Flags to pass to `npm ci`.
      '';
      example = [
        "--ignore-scripts"
      ];
    };
  };
}
