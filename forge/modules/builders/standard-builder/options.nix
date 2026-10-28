{
  lib,
  pkgs,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Standard builder for autotools, CMake, or Makefile-based projects.

      Uses `stdenv.mkDerivation` from Nixpkgs, which supports the standard
      GNU build system (`./configure && make && make install`).

      For more information, see the
      [Nixpkgs stdenv documentation](https://nixos.org/manual/nixpkgs/unstable/#chap-stdenv)
    '';

    stdenv = lib.mkOption {
      type = with lib.types; either package (functionTo package);
      default = pkgs.stdenv;
      defaultText = lib.literalExpression "pkgs.stdenv";
      example = lib.literalExpression "pkgs: pkgs.stdenvNoCC";
      description = ''
        The stdenv used for the build. Can be a package or a function `pkgs: package`.

        Override to use a different compiler toolchain or to strip down the
        build environment. For example, use `pkgs.stdenvNoCC` for packages
        that do not require a C compiler, or `pkgs.clangStdenv` to build
        with Clang instead of GCC.
      '';
    };
  };
}
