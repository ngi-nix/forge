{
  mkDerivation,
  mkDerivationProvidesFinalAttrs ? true,
  name,
  imports ? { },
  parentImports ? [ ],
  attrs,
}@builderArgs:
{
  config,
  forge-inputs,
  forge-lib,
  lib,
  pkgs,
  ...
}@args:
let
  builder = config.build.builders.${builderArgs.name};
in
{
  imports = parentImports;
  options.build = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        (lib.modules.importApply builder/aliases.nix builderArgs)
        # For each builder
        ({ config, ... }: {
          options.builders = lib.mkOption {
            type = lib.types.submoduleWith {
              modules = [
                ({ specialArgs, config, ... }: {
                  options.${builderArgs.name} = lib.mkOption {
                    description = "Builder";
                    default = { };
                    type = lib.types.submoduleWith {
                      inherit specialArgs;
                      modules = [
                        builderArgs.imports
                        ../env/options.nix
                        ../structuredAttrs/options.nix
                      ];
                    };
                  };
                })
              ];
            };
          };
        })
        {
          # Synthesize builder-specific config to build.
          config = lib.mkIf config.build.builders.${builderArgs.name}.enable {
            inherit (config.build.builders.${builderArgs.name}) env structuredAttrs;
          };
        }
      ];
    };
  };

  config = lib.mkIf builder.enable {
    result.derivation =
      let
        mkSharedAttrs =
          finalAttrs:
          config.build.structuredAttrs
          // config.result.derivationAttrs
          // {
            inherit (config)
              pname
              version
              ;

            src = import builder/src.nix args;

            __structuredAttrs = true;
            inherit (config.build) env;

            passthru = {
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

              forge = {
                broken = config.broken;
              };
            }
            // lib.optionalAttrs (!config.test.broken) {
              test = config.test.derivation { inherit pkgs finalAttrs; };
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
          // {
            shellHook = ''
              echo "ngi-forge: '${finalAttrs.pname}' is available at version '${finalAttrs.version}'."
            ''
            + lib.optionalString config.build.debug ''
              source ${forge-inputs.nix-utils}/nix-develop-interactive.bash
            '';
          }
          //
            # Warning(co-existence): `extraAttrs` is overridden by the builder's options.
            # Eg. in `builders.go`, if `modRoot` is set in `extraAttrs.modRoot`
            # instead of `build.builders.go.modRoot`,
            # then `build.builders.go.modRoot`'s default
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
            builderAttrs = builderArgs.attrs builder finalAttrs sharedAttrs;
          in
          sharedAttrs // builderAttrs;
      in
      if mkDerivationProvidesFinalAttrs then
        builderArgs.mkDerivation mkDrvAttrs
      else
        let
          # Approximation for builder not yet providing `finalAttrs`
          # (eg. with `lib.extendMkDerivation`)
          finalAttrs = mkSharedAttrs finalAttrs // {
            finalPackage = config.result.derivation;
          };
        in
        builderArgs.mkDerivation (mkDrvAttrs finalAttrs);
  };
}
