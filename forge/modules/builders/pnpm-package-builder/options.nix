{
  lib,
  ...
}:
{
  options.build.pnpmPackageBuilder = {
    enable = lib.mkEnableOption ''
      PNPM package builder for JavaScript/TypeScript packages.

      Uses fetchPnpmDeps and stdenvNoCC.mkDerivation with pnpmConfigHook'';

    packages = {
      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Build-time dependencies (native architecture).

          Tools needed during compilation that run on the build machine.
        '';
      };
      run = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Runtime dependencies (target architecture).

          Libraries needed by the package at runtime.
        '';
      };
      check = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Test dependencies.";
      };
    };

    fetcherVersion = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = ''
        Version of the pnpm fetcher to use (passed to fetchPnpmDeps as fetcherVersion).

        Version 3 supports pnpm lockfile v9 (pnpm >= 9). Use version 1 for older lockfiles.
      '';
      example = 1;
    };

    pnpmDepsHash = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        SHA256 hash of the fetched pnpm dependencies.

        Leave empty initially - nix will provide the correct hash on first build.
      '';
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    buildScript = lib.mkOption {
      type = lib.types.str;
      default = "build";
      description = "The pnpm script to run for building (passed to pnpm run).";
      example = "build";
    };

    installDir = lib.mkOption {
      type = lib.types.str;
      default = "dist";
      description = "Directory containing build output to install to \$out.";
      example = "dist";
    };

    sourceRoot = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to the subdirectory within the source containing pnpm-lock.yaml.
        Format: "source/<subdir>" (e.g. "source/frontend").
        The builder will also set sourceRoot for the derivation to cd into this directory.
      '';
      example = "source/frontend";
    };
  };
}
