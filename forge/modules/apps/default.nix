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
          passthru = mkPassthru app appDrv;
        });

      mkPassthru =
        app: finalApp:
        let
          testProgramsDrv = pkgs.testers.runCommand {
            name = "${app.name}-test";
            buildInputs = [ finalApp ] ++ app.test.programs.packages;
            script = ''
              ${app.test.programs.script}
              touch $out
            '';
          };
          tests =
            lib.optionalAttrs (app.services.runtimes.container.enable && app.test.services.script != "") {
              test-services-container = app.test.services.result.containerBuild;
            }
            // lib.optionalAttrs (app.services.runtimes.nixos.enable && app.test.services.script != "") {
              test-services-nixos = app.test.services.result.build;
            }
            // lib.optionalAttrs (app.test.programs.script != "") {
              test-programs = testProgramsDrv;
            };
        in
        lib.fix (self: {
          config = app;
        })
        // lib.optionalAttrs app.programs.runtimes.program.enable {
          program = app.programs.mainPackage;
        }
        // lib.optionalAttrs app.services.runtimes.container.enable {
          container = app.services.runtimes.container.result.build;
          services = app.services.runtimes.container.result.shellRunner;
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
          check-programs-main-package =
            assert
              (app.programs.mainPackage != null)
              || throw "${app.name} has runtimes.program.enable but programs.mainPackage is missing";
            assert
              (lib.hasAttrByPath [ "meta" "mainProgram" ] app.programs.mainPackage)
              || throw "${app.name}'s programs.mainPackage is missing a meta.mainProgram attribute";
            app.programs.mainPackage;
        }
        // tests
        // {
          test = pkgs.linkFarm "${app.name}-tests" (
            lib.mapAttrsToList (name: path: {
              name = lib.removePrefix "test-" name;
              inherit path;
            }) tests
          );
        };
    in
    {
      packages = lib.mapAttrs' (appName: app: {
        # Insert the -app suffix to create a namespace for applications.
        name = "${appName}-app";
        value = shellBundle app;
      }) config.forge.apps;
    };
}
