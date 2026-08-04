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
      example = [ "--ignore-scripts" ];
    };
  };
}
