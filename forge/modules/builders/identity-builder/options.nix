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
        Attribute path in Nixpkgs to expose directly as this package, e.g. `"hello"` or `"python3Packages.requests"`.

        When `nixpkgsPin` is specified, this attribute resolves directly from the pinned Nixpkgs set.
      '';
      example = "hello";
    };
    derivation = lib.mkOption {
      type = with lib.types; either package (functionTo package);
      description = ''
        Resulting package derivation. Can be a derivation or a function `pkgs: derivation`.

        When defined as a function `pkgs: ...`, `pkgs` refers to the package's effective Nixpkgs
        (which respects `nixpkgsPin` if specified).
      '';
      example = lib.literalExpression "pkgs: pkgs.hello";
    };
  };
  config = {
    # `flake-parts-lib.mkPerSystemOption` does not provide `specialArgs.system`
    # inside `options`, hence use `pkgs` in `config` to set a `default`.
    # Setting a `default` is required for `_forge.config`.
    derivation = lib.mkOptionDefault pkgs.emptyDirectory;
  };
}
