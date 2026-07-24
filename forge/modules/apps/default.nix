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
      getAppInputs =
        app:
        let
          # Returns a list of packages from each attribute path
          collectPackages =
            attrs: attrPath:
            lib.pipe attrs [
              (lib.mapAttrsToList (_: lib.attrByPath attrPath [ ]))
              (lib.flatten)
            ];

          # NOTE: it might be worth it to collect these internally through the
          # module system such that we can use them in other places (e.g. in the UI)
          packages = {
            programs = app.programs.packages;
            components = collectPackages app.services.components [
              "process"
              "packages"
            ];
            containerComponents = collectPackages app.services.runtimes.container.components [
              "packages"
            ];
            nixos = app.services.runtimes.nixos.packages;
            test = app.test.programs.packages ++ app.test.services.packages;
          };

          inputsFrom = lib.flatten (lib.attrValues packages);
        in
        inputsFrom;

      shellBundle =
        app:
        let
          inputsFrom = getAppInputs app;

          # Adapted from Nixpkgs (pkgs/build-support/mkshell/default.nix)
          #
          # Used to collect all app packages' inputs, which may later be
          # consumed by devShells.
          mergeInputs =
            name:
            # 1. get all `{build,nativeBuild,...}Inputs` from the elements of `inputsFrom`
            # 2. since that is a list of lists, `flatten` that into a regular list
            # 3. filter out of the result everything that's in `inputsFrom` itself
            # this leaves actual dependencies of the derivations in `inputsFrom`, but never the derivations themselves
            (lib.subtractLists inputsFrom (lib.flatten (lib.catAttrs name inputsFrom)));

          appDrv = pkgs.symlinkJoin {
            name = "${app.name}";
            paths = app.programs.packages;
          };
        in
        # Passthru
        appDrv.overrideAttrs (_: {
          buildInputs = mergeInputs "buildInputs";
          nativeBuildInputs = mergeInputs "nativeBuildInputs";
          propagatedBuildInputs = mergeInputs "propagatedBuildInputs";
          propagatedNativeBuildInputs = mergeInputs "propagatedNativeBuildInputs";
          passthru = mkPassthru app appDrv;
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

          inputsFrom = getAppInputs app;
        in
        lib.fix (self: {
          config = app;
          pkgs = inputsFrom;
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
