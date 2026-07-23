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
