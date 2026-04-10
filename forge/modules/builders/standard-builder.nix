{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
    perSystem = mkPerSystemOption (
      {
        config,
        pkgs,
        sharedBuildAttrs,
        ...
      }:
      {
        options = {
          forge.packages = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  build.standardBuilder = {
                    enable = lib.mkEnableOption ''
                      Standard builder for autotools, CMake, or Makefile-based projects.

                      Automatically handles configure, build, and install phases'';
                    requirements = {
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
                  };
                };
              }
            );
          };
        };

        config = {
          packages =
            let
              cfg = config.forge.packages;

              standardBuilderPkgs = lib.listToAttrs (
                map (pkg: {
                  name = pkg.name;
                  value = pkgs.callPackage (
                    # Derivation start
                    { stdenv }:
                    stdenv.mkDerivation (
                      finalAttrs:
                      {
                        pname = pkg.name;
                        version = pkg.version;
                        src = sharedBuildAttrs.pkgSource pkg;
                        patches = pkg.source.patches;
                        nativeBuildInputs = pkg.build.standardBuilder.requirements.build;
                        buildInputs = pkg.build.standardBuilder.requirements.run;
                        nativeCheckInputs = pkg.build.standardBuilder.requirements.check;
                        passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                        meta = sharedBuildAttrs.pkgMeta pkg;
                      }
                      // pkg.build.extraAttrs
                      // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                    )
                    # Derivation end
                  ) { };
                }) (lib.filter (p: p.build.standardBuilder.enable == true) cfg)
              );
            in
            standardBuilderPkgs;
        };
      }
    );
  };
}
