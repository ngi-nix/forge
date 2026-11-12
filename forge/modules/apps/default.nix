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
                    { apps.${name}.parameters = lib.mapAttrs (_: value: { value = lib.mkForce value; }) parameters; }
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
          forge.broken = app.broken;
          forge.unfree = app.unfree;
          packages = app.packages;
          # Change the parameters of the app, for example
          # `apps.<name>.override { port = 9090; }`.
          override =
            parameters:
            let
              checked = forge-lib.checkParameters app.name app.parameters parameters;
            in
            # Report invalid parameters even if no app output reads them.
            lib.seq checked (
              # Keep the parameters set by earlier `override` calls,
              # because `appWithParameters` starts again from the recipe.
              bundle (config.forge.appWithParameters app.name (app.parameters // checked))
            );
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

      # TODO: collect disabled apps and print warnings?
      enabledApps = lib.filterAttrs (_: app: !app.broken && !app.unfree && app.enable) config.forge.apps;

      # App warnings and assertions are checked only when the app is evaluated,
      # to not slow down evaluation of other flake outputs.
      bundle =
        app: forge-lib.checkAssertionsWarnings { inherit (app) assertions warnings; } (shellBundle app);

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
