{
  lib,
  ...
}:
{
  options.build.npmPackageBuilder = {
    enable = lib.mkEnableOption ''
      NPM package builder for JavaScript and TypeScript packages.

      Uses `buildNpmPackage` from Nixpkgs, which builds Node.js packages
      using `npm ci` with a locked dependency set from `package-lock.json`.
      Node.js is automatically included as a build-time dependency.

      For more information, see the
      [Nixpkgs Node.js documentation](https://nixos.org/manual/nixpkgs/unstable/#language-javascript)
    '';

    packages = {
      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of additional build-time dependencies needed during compilation (native architecture).

          Node.js is included automatically.

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

    npmDepsHash = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Hash of the npm dependencies fetched from `package-lock.json`.

        Leave empty initially to let Nix print the correct hash on first build.

        Mapped to `npmDepsHash`.
      '';
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    npmInstallFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional flags passed to `npm ci` during the install phase.

        Mapped to `npmInstallFlags`.
      '';
      example = lib.literalExpression ''[ "--ignore-scripts" ]'';
    };
  };
}
