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
          { specialArgs, extendModules, ... }@forgeArgs:
          {
            config = {
              # Convenient alias to use `apps` instead of `config.apps`
              _module.args.apps = forgeArgs.config.apps;

              # Evaluate all recipes again, so that the recipe of the app,
              # which reads its parameters from `config.apps.<name>`,
              # gets the new values.
              appWithParameters =
                name: parameters:
                (extendModules {
                  modules = [
                    {
                      apps.${name} = {
                        parameters = lib.mapAttrs (_: value: { value = lib.mkForce value; }) parameters;
                        overriddenParameters = parameters;
                      };
                    }
                  ];
                }).config.apps.${name};
            };
            options.appWithParameters = lib.mkOption {
              type = lib.types.raw;
              internal = true;
              readOnly = true;
              description = "Function returning the app `name` with the `parameters` set.";
            };
            options.apps = lib.mkOption {
              default = { };
              description = "Applications indexed by their `name`.";
              type = lib.types.attrsOf (
                lib.types.submoduleWith {
                  specialArgs = specialArgs // {
                    enable = forgeArgs.config.enable;
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
          inherit (app) test;
          inherit (app.services) runtimes;

          isRunnable = t: t.script != "" && !t.broken;

          hasServicesTest = isRunnable test.services;
          hasProgramsTest = isRunnable test.programs;

          tests = lib.mergeAttrsList [
            (lib.optionalAttrs (hasServicesTest && runtimes.container.enable) {
              test-services-container = test.services.result.containerBuild;
            })
            (lib.optionalAttrs (hasServicesTest && runtimes.nixos.enable) {
              test-services-nixos = test.services.result.build;
            })
            (lib.optionalAttrs hasProgramsTest {
              test-programs = test.programs.derivation {
                inherit pkgs finalApp;
                inherit (app.programs) mainPackage;
              };
            })
          ];
        in
        lib.fix (self: {
          config = app;
          forge._recipeType = app._recipeType;
          forge.broken = app.broken;
          forge.unfree = app.unfree;
          packages = app.packages;
          # Return a new version of the app with parameters overwritten.
          #
          # For example, if `apps.<name>` declares `port = 8080;`, we can:
          # `apps.<name>.override { port = 9090; }`
          override =
            newParameters:
            let
              oldParameters = app.parameters;

              # Assert that new parameters are declared by the app, with the same types.
              checkedParameters = forge-lib.checkParameters {
                appName = app.name;
                declaredParameters = oldParameters;
                parameters = newParameters;
              };

              # Keep the parameters set by earlier `override` calls,
              # because `appWithParameters` starts again from the recipe.
              # Keep only these, not all values, so that the value of a
              # parameter can use the values of other parameters.
              allParameters = app.overriddenParameters // checkedParameters;

              newApp = bundle (config.forge.appWithParameters app.name allParameters);
            in
            # Evaluate and check all parameters, so we catch all invalid ones,
            # even if no app output reads them. Then, return the overwritten app.
            lib.seq checkedParameters newApp;
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
          # The `programs.mainPackage` checks are app assertions (see `app.nix`),
          # which run whenever the app is evaluated.
          check-programs-main-package = app.programs.mainPackage;
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

      enabledApps = lib.filterAttrs (_: app: !app.broken && app.enable) config.forge.apps;

      handleUnfree = forge-lib.handleUnfree pkgs;

      # App warnings and assertions are checked only when the app is evaluated,
      # to not slow down evaluation of other flake outputs.
      bundle =
        app:
        forge-lib.checkAssertionsWarnings { inherit (app) assertions warnings; } (
          handleUnfree (shellBundle app)
        );

      bundledApps = lib.mapAttrs (_: bundle) enabledApps;
      packagesWithNamespace = pkgs.callPackage (forge-lib.flakePackagesWithNamespace {
        namespace = "apps";
        derivations = bundledApps;
      }) { };
    in
    {
      # Output names are computed from the app configuration, not from
      # `bundledApps`, to avoid evaluating every app when accessing `packages`.
      packages =
        packagesWithNamespace.packages
        // lib.concatMapAttrs (
          appName: app:
          let
            bundled = bundledApps.${appName};
          in
          lib.optionalAttrs app.services.runtimes.container.enable {
            "apps.${appName}.container" = bundled.container;
          }
          // lib.optionalAttrs app.programs.runtimes.program.enable {
            "apps.${appName}.program" = bundled.program;
          }
          // lib.optionalAttrs app.services.runtimes.nixos.enable { "apps.${appName}.vm" = bundled.vm; }
        ) enabledApps;
    };
}
