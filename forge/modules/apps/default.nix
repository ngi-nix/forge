{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.forge = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        (
          { specialArgs, ... }@forgeArgs:
          {
            config = {
              # Convenient alias to use `apps` instead of `config.apps`
              _module.args.apps = forgeArgs.config.apps;
            };
            options.apps = lib.mkOption {
              default = { };
              description = "Applications indexed by their `name`.";
              type = lib.types.attrsOf (
                lib.types.submoduleWith {
                  inherit specialArgs;
                  modules = [ ./app.nix ];
                }
              );
            };
          }
        )
      ];
    };
  };

  config =
    let
      shellBundle =
        app:
        let
          appDrv = pkgs.symlinkJoin {
            name = "${app.name}";
            paths = app.programs.packages;
          };
        in
        # Passthru
        appDrv.overrideAttrs (_: {
          passthru = appPassthru app appDrv;
        });

      mkPassthru =
        app:
        lib.fix (self: {
          config = app;
        })
        // lib.optionalAttrs app.programs.runtimes.program.enable {
          program = app.programs.mainPackage;
        }
        // lib.optionalAttrs app.services.runtimes.container.enable {
          container = app.services.runtimes.container.result.build;
        }
        // lib.optionalAttrs app.services.runtimes.nixos.enable {
          vm = app.services.runtimes.nixos.result.build;
          nixosModules.default = app.services.runtimes.nixos.result.nixosModule;
          nixos = {
            modules = app.services.runtimes.nixos.result.modules;
            vm = app.services.runtimes.nixos.result.build;
          };
        }
        // lib.optionalAttrs app.programs.runtimes.program.enable {
          test-program =
            assert
              (app.programs.mainPackage != null)
              || throw "${app.name} has runtimes.program.enable but programs.mainPackage is missing";
            assert
              (lib.hasAttrByPath [ "meta" "mainProgram" ] app.programs.mainPackage)
              || throw "${app.name}'s programs.mainPackage is missing a meta.mainProgram attribute";
            app.programs.mainPackage;
        }
        // lib.optionalAttrs (app.services.runtimes.container.enable && app.test.script != "") {
          test-container = app.test.result.containerBuild;
        }
        // lib.optionalAttrs (app.services.runtimes.nixos.enable && app.test.script != "") {
          test = app.test.result.build;
        };

      # finalApp parameter is currently not used in this function
      appPassthru = app: finalApp: mkPassthru app;
    in
    {
      packages = lib.mapAttrs' (appName: app: {
        # Insert the -app suffix to create a namespace for applications.
        name = "${appName}-app";
        value = shellBundle app;
      }) config.forge.apps;
    };
}
