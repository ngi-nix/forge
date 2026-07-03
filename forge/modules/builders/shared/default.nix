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
        name,
        imports ? { },
        attrs,
      }:
      {
        config,
        options,
        pkgs,
        lib,
        forge-lib,
        ...
      }@args:
      let
        builder = config.build.${name};
      in
      {
        imports = [
          (forge-lib.mkAliasOptionModule {
            condition = builder.enable;
            from = [
              "build"
              name
              "packages"
              "build"
            ];
            to = [
              "phases"
              "build"
              "packages"
              "build"
              "host"
            ];
          })
          (forge-lib.mkAliasOptionModule {
            condition = builder.enable;
            from = [
              "build"
              name
              "packages"
              "run"
            ];
            to = [
              "phases"
              "build"
              "packages"
              "host"
              "target"
            ];
          })
          (forge-lib.mkAliasOptionModule {
            condition = builder.enable;
            from = [
              "build"
              name
              "packages"
              "check"
            ];
            to = [
              "phases"
              "check"
              "packages"
              "build"
              "host"
            ];
          })
        ];
        options.build = lib.mkOption {
          type = lib.types.submoduleWith {
            modules = [
              ./env.nix
              ./structuredAttrs.nix
              ({ specialArgs, config, ... }: {
                options.${name} = lib.mkOption {
                  default = { };
                  type = lib.types.submoduleWith {
                    inherit specialArgs;
                    modules = [
                      imports
                      ./env.nix
                      ./structuredAttrs.nix
                    ];
                  };
                };
                config = lib.mkIf config.${name}.enable {
                  inherit (config.${name}) env structuredAttrs;
                };
              })
            ];
          };
        };

        config = lib.mkIf builder.enable {
          result.derivation =
            let
              mkSharedAttrs =
                finalAttrs:
                config.build.structuredAttrs
                // (config.result.derivationAttrs)
                // {
                  inherit (config)
                    pname
                    version
                    ;

                  src = import ./src.nix args;

                  __structuredAttrs = true;
                  inherit (config.build) env;

                  nativeBuildInputs = builder.packages.build;
                  buildInputs = builder.packages.run;

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
