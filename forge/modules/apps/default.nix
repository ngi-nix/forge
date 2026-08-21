{
  config,
  lib,
  forge-lib,
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
                  specialArgs = specialArgs // {
                    forgeOptions = forgeArgs.options;
                  };
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
          # Collect all of the packages into one derivation.
          appDrv = pkgs.symlinkJoin {
            name = "${app.name}";
            paths = app.programs.packages;
          };
          overridePackageWithName =
            packageName: newArgs:
            let
              matches = p: lib.strings.getName p == packageName;
              packageMatched = lib.any matches app.programs.packages;

              newApp = app // {
                programs = app.programs // {
                  # If package name matches packageName, then we override it.
                  packages = map (p: if matches p then p.override newArgs else p) app.programs.packages;
                };
              };
            in
            assert
              packageMatched
              || throw "${packageName} does not match any of the packages in the packages of ${app.name}.";
            shellBundle newApp;
        in
        appDrv.overrideAttrs (_: {
          passthru = (mkPassthru app appDrv) // {
            override = overridePackageWithName app.name;

            /**
              To override a specific package within the packages list,
              It should be indicated in the documentation of the package when this is necessary.

              This is to handle cases like the one described in the example of the shell runtime
              in the documentation.
            */
            overridePackage = overridePackageWithName;
          };
        });

      mkPassthru =
        app: finalApp:
        let
          testProgramsDrv = pkgs.testers.runCommand {
            name = "${app.name}-test";
            buildInputs = [
              finalApp
            ]
            ++ lib.optional (app.programs.mainPackage != null) app.programs.mainPackage
            ++ app.test.programs.packages;
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
          forge.broken = app.broken;
          pkgs = app.packagesList;
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

      # For each app, shellBundle it
      bundledApps = lib.mapAttrs (appName: app: shellBundle app) config.forge.apps;
      packagesWithNamespace = pkgs.callPackage (forge-lib.flakePackagesWithNamespace {
        namespace = "apps";
        derivations = bundledApps;
      }) { };
    in
    {
      packages =
        packagesWithNamespace.packages
        // lib.concatMapAttrs (
          appName: bundled:
          { }
          // lib.optionalAttrs (bundled ? container) { "apps.${appName}.container" = bundled.container; }
          // lib.optionalAttrs (bundled ? program) { "apps.${appName}.program" = bundled.program; }
          // lib.optionalAttrs (bundled ? vm) { "apps.${appName}.vm" = bundled.vm; }
        ) bundledApps;

    };
}
