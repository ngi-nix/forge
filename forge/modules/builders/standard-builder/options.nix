{
  lib,
  pkgs,
  ...
}:
{
  options.build.standardBuilder = {
    enable = lib.mkEnableOption ''
      Standard builder for autotools, CMake, or Makefile-based projects.

      Automatically handles configure, build, and install phases'';
    packages = {
      build = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Build-time dependencies (native architecture).

          Tools needed during compilation that run on the build machine.
        '';
        example = lib.literalExpression "[ pkgs.cmake pkgs.pkg-config pkgs.ninja ]";
      };
      run = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Runtime dependencies (target architecture).

          Libraries needed by the package at runtime.
        '';
        example = lib.literalExpression "[ pkgs.openssl pkgs.sqlite pkgs.zlib ]";
      };
      check = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Test dependencies.

          Packages needed to run tests.
        '';
        example = lib.literalExpression "[ pkgs.cunit ]";
      };
    };

    stdenv = lib.mkOption {
      type = lib.types.package;
      default = pkgs.stdenv;
      defaultText = lib.literalExpression "pkgs.stdenv";
      example = lib.literalExpression "pkgs.stdenvNoCC";
      description = ''
        The stdenv to use for the build.
      '';
    };
  };
}
