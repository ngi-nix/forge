{
  lib,
  ...
}:
{
  options.build.pnpmPackageBuilder = {
    enable = lib.mkEnableOption ''
      PNPM package builder for JavaScript and TypeScript packages.

      Uses `fetchPnpmDeps` and `stdenvNoCC.mkDerivation` with `pnpmConfigHook`
      from Nixpkgs, which builds Node.js packages using pnpm with a locked
      dependency set from `pnpm-lock.yaml`.
      Node.js and pnpm are automatically included as build-time dependencies.

      For more information, see the
      [Nixpkgs Node.js documentation](https://nixos.org/manual/nixpkgs/unstable/#language-javascript)
    '';

    packages = {
      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of additional build-time dependencies needed during compilation (native architecture).

          Node.js and pnpm are included automatically.

          Mapped to `nativeBuildInputs`.
        '';
        example = lib.literalExpression "[ pkgs.pkg-config ]";
      };
      run = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of runtime dependencies needed by the package (target architecture).

          Mapped to `buildInputs`.
        '';
        example = lib.literalExpression "[ pkgs.vips ]";
      };
      check = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of test dependencies needed to run the test suite.

          Mapped to `nativeCheckInputs`.
        '';
        example = lib.literalExpression "[ pkgs.chromium ]";
      };
    };

    fetcherVersion = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = ''
        Version of the pnpm fetcher to use.

        Version 3 supports pnpm lockfile v9 (pnpm >= 9).
        Use version 1 for older lockfiles.

        Mapped to `fetcherVersion`.
      '';
      example = 1;
    };

    pnpmDepsHash = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Hash of the fetched pnpm dependencies.

        Leave empty initially to let Nix print the correct hash on first build.

        Mapped to `hash` in `fetchPnpmDeps`.
      '';
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    buildScript = lib.mkOption {
      type = lib.types.str;
      default = "build";
      description = ''
        The pnpm script to run for building (`pnpm run <script>`).

        Mapped to `buildScript`.
      '';
      example = "build:prod";
    };

    installDir = lib.mkOption {
      type = lib.types.str;
      default = "dist";
      description = ''
        Directory containing the build output to install into `$out`.

        Mapped to `installDir`.
      '';
      example = "build";
    };

    sourceRoot = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to the subdirectory within the source containing `pnpm-lock.yaml`.

        Use this for monorepos where the pnpm workspace is not at the repository root.
        Format: `"source/<subdir>"`.

        Mapped to `sourceRoot`.
      '';
      example = "source/frontend";
    };
  };
}
