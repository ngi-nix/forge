{
  lib,
  pkgs,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Identity builder to provide a derivation directly
      (eg. from Nixpkgs using `pkgs.pkgsOriginal`).
    '';
    attribute = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Attribute path in Nixpkgs, e.g. "garage_2" or "badkeys".
        When nixpkgsPin is set, this resolves from the pinned Nixpkgs.
      '';
    };
    derivation = lib.mkOption {
      type = lib.types.package;
      description = "Resulting package derivation.";
    };
  };
  config = {
    # `flake-parts-lib.mkPerSystemOption` does not provide `specialArgs.system`
    # inside `options`, hence use `pkgs` in `config` to set a `default`.
    # Setting a `default` is required for `_forge.config`.
    derivation = lib.mkOptionDefault pkgs.emptyDirectory;
  };
}
