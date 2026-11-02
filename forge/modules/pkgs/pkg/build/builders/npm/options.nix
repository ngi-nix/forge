{
  lib,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      NPM package builder for JavaScript and TypeScript packages.

      Uses `buildNpmPackage` from Nixpkgs, which builds Node.js packages
      using `npm ci` with a locked dependency set from `package-lock.json`.
      Node.js is automatically included as a build-time dependency.

      For more information, see the
      [Nixpkgs Node.js documentation](https://nixos.org/manual/nixpkgs/unstable/#language-javascript)
    '';

    dontNpmBuild = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to disable the `npm` build script.

        Mapped to `dontNpmBuild`.
      '';
    };

    vendoredSbom = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether the SBOM of the package also lists the vendored dependencies.

        Set this to `false` if `package.json` has dependencies that `npm sbom` cannot find,
        for example a `file:` dependency outside of the package source.
      '';
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

    npmFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional flags passed to all `npm` commands.

        Mapped to `npmFlags`.
      '';
    };

    npmInstallFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional flags passed to `npm ci` during the install phase.

        Mapped to `npmInstallFlags`.
      '';
      example = [ "--ignore-scripts" ];
    };
  };
}
