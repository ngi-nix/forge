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

          testInstructionFlow =
            { name, instructions }:
            pkgs.testers.runCommand {
              name = "${name}-instructions-test";
              buildInputs = [
                finalApp
              ]
              ++ lib.optional (app.programs.mainPackage != null) app.programs.mainPackage
              ++ app.test.programs.packages;

              script = ''
                ${builtins.foldl' (
                  acc: curr:
                  lib.concatLines [
                    acc
                    (if curr.command != null then lib.trim curr.command else "# No command for instruction")
                  ]
                ) "" instructions}
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
            }
            // lib.optionalAttrs (app.instructionFlows != [ ]) {
              test-instruction-flow = lib.attrsets.mergeAttrsList (
                map (instructionFlow: {
                  "${instructionFlow.name}" = testInstructionFlow {
                    name = instructionFlow.name;
                    instructions = instructionFlow.flow;
                  };
                }) app.instructionFlows
              );

              test-all-instruction-flows =
                pkgs.runCommand "run-all"
                  {
                    buildInputs = builtins.attrValues tests.test-instruction-flow;
                  }
                  ''
                    touch $out
                  '';
            };

          skippedTests = [ "test-instruction-flow" ];
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
            }) (lib.filterAttrs (name: _value: !(builtins.any (t: name == t) skippedTests)) tests)
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

      warnings = [
        {
          condition = lib.attrsets.filterAttrs (_: app: app.usage != null) config.forge.apps != { };
          message = ''
            Apps {${
              lib.join "," (
                map (app: app.name) (lib.filter (app: app.usage != null) (lib.attrValues config.forge.apps))
              )
            }}: The `usage` field is deprecated in favour of a combination of `longDescription` and `instructionFlows`.
          '';
        }
      ];

      assertions = lib.flatten (
        map (app: [
          {
            condition = lib.lists.allUnique (map (insFlow: insFlow.name) app.instructionFlows);
            message = "${toString app.name} has two instruction flows with the same name";
          }
        ]) (lib.attrValues config.forge.apps)
      );
    };
}
