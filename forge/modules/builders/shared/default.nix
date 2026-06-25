{
  forge-inputs,
  ...
}:
{
  config = {
    _module.args.packageBuilderModule =
      {
        mkDerivation,
        mkDerivationProvidesFinalAttrs ? true,
        builderName,
        attrs,
      }:
      {
        config,
        pkgs,
        lib,
        ...
      }@args:

      let
        builder = config.build.${builderName};
      in

      {
        options.build.${builderName} = {
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
        };

        config = lib.mkIf builder.enable {
          result.derivation =
            let
              mkSharedAttrs =
                finalAttrs:
                {
                  inherit (config)
                    pname
                    version
                    ;

                  src = import ./src.nix args;

                  inherit (config.source)
                    patches
                    ;

                  nativeBuildInputs = builder.packages.build;
                  buildInputs = builder.packages.run;
                  nativeCheckInputs = builder.packages.check;

                  passthru = {
                    test = pkgs.testers.runCommand {
                      name = "${finalAttrs.pname}-test";
                      buildInputs = [ finalAttrs.finalPackage ] ++ config.test.packages;
                      script = config.test.script + "\ntouch $out";
                    };

                    env = pkgs.mkShell {
                      dontBuild = true;
                      phases = [ "installPhase" ];
                      installPhase = "touch $out";
                      env.ENV_PACKAGE_NAME = finalAttrs.pname;
                      env.ENV_PACKAGE_SOURCE = "${finalAttrs.src}";
                      inputsFrom = [
                        finalAttrs.finalPackage
                      ];
                      packages = config.develop.packages;
                      shellHook = config.develop.shellHook;
                    };
                  };

                  meta = {
                    inherit (config)
                      description
                      mainProgram
                      license
                      ;
                    homepage = config.homePage;
                  };
                }
                // lib.optionalAttrs config.build.debug {
                  shellHook = "source ${forge-inputs.inputs.nix-utils}/nix-develop-interactive.bash";
                }
                //
                  # Warning(co-existence): `extraAttrs` is overridden by the builder's options.
                  # Eg. in `goPackageBuilder`, if `modRoot` is set in `extraAttrs.modRoot`
                  # instead of `build.goPackageBuilder.modRoot`,
                  # then `build.goPackageBuilder.modRoot`'s default
                  # will override `extraAttrs.modRoot`.
                  #
                  # This deprioritizing offen leads to a build failure
                  # which helps to spot lingering `build.extraAttrs`
                  # that must be converted once a proper option
                  # has been introduced (eg. to typecheck/merge them).
                  config.build.extraAttrs;

              mkDrvAttrs =
                finalAttrs:
                let
                  sharedAttrs = mkSharedAttrs finalAttrs;
                  builderAttrs = attrs builder finalAttrs sharedAttrs;
                in
                sharedAttrs // builderAttrs;
            in
            if mkDerivationProvidesFinalAttrs then
              mkDerivation mkDrvAttrs
            else
              let
                # Approximation for builder not yet providing `finalAttrs`
                # (eg. with `lib.extendMkDerivation`)
                finalAttrs = mkSharedAttrs finalAttrs // {
                  finalPackage = config.result.derivation;
                };
              in
              mkDerivation (mkDrvAttrs finalAttrs);
        };
      };
  };
}
