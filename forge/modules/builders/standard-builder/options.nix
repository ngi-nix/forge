{
  lib,
  nixpkgs-pkgs,
  ...
}:
{
  options.build.standardBuilder = {
    enable = lib.mkEnableOption ''
      Standard builder for autotools, CMake, or Makefile-based projects.

      Uses `stdenv.mkDerivation` from Nixpkgs, which supports the standard
      GNU build system (`./configure && make && make install`).

      For more information, see the
      [Nixpkgs stdenv documentation](https://nixos.org/manual/nixpkgs/unstable/#chap-stdenv)
    '';
    packages = {
      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of build-time dependencies needed during compilation (native
          architecture).

          Mapped to `nativeBuildInputs`.
        '';
        example = lib.literalExpression "[ pkgs.cmake pkgs.pkg-config pkgs.ninja ]";
      };
      run = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of runtime dependencies needed by the package (target
          architecture).

          Mapped to `buildInputs`.
        '';
        example = lib.literalExpression "[ pkgs.openssl pkgs.sqlite pkgs.zlib ]";
      };
      check = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          List of test dependencies needed to run the test suite.

          Mapped to `nativeCheckInputs`.
        '';
        example = lib.literalExpression "[ pkgs.cunit ]";
      };
    };

    stdenv = lib.mkOption {
      type = lib.types.package;
      default = nixpkgs-pkgs.stdenv;
      defaultText = lib.literalExpression "pkgs.stdenv";
      example = lib.literalExpression "pkgs.stdenvNoCC";
      description = ''
        The stdenv used for the build.

        Override to use a different compiler toolchain or to strip down the
        build environment. For example, use `pkgs.stdenvNoCC` for packages
        that do not require a C compiler, or `pkgs.clangStdenv` to build
        with Clang instead of GCC.
      '';
    };
  };
}
