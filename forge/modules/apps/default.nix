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
          browserRuntime = app.programs.runtimes.browser;
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
            }
            // lib.optionalAttrs (browserRuntime.enable && browserRuntime.wasmPackage != null) {
              # Run the example that the browser shows.
              test-browser = pkgs.testers.runCommand {
                name = "${app.name}-test-browser";
                nativeBuildInputs = [
                  pkgs.python3
                  pkgs.wasmtime
                ];
                # `args` is an attribute of `derivation`.
                exampleArgs = browserRuntime.args;
                exampleStdin = browserRuntime.stdin;
                passAsFile = [ "exampleStdin" ];
                # `shlex.split` splits the arguments as the browser does.
                script = ''
                  # Wasmtime writes its cache to `$HOME`.
                  export HOME=$TMPDIR
                  python3 -c '
                  import shlex, subprocess, sys
                  args = ["wasmtime", "run", sys.argv[1]] + shlex.split(sys.argv[2])
                  sys.exit(subprocess.run(args).returncode)
                  ' \
                    ${browserRuntime.wasmPackage}/bin/${browserRuntime.wasmProgram}.wasm \
                    "$exampleArgs" \
                    < "$exampleStdinPath"
                  touch $out
                '';
              };
            };
        in
        lib.fix (self: {
          config = app;
          forge.broken = app.broken;
          packages = app.packages;
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
        // lib.optionalAttrs (browserRuntime.enable && browserRuntime.wasmPackage != null) {
          browser = browserRuntime.wasmPackage;
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

      # App warnings and assertions are checked only when the app is evaluated,
      # to not slow down evaluation of other flake outputs.
      bundledApps = lib.mapAttrs (
        appName: app:
        forge-lib.checkAssertionsWarnings { inherit (app) assertions warnings; } (shellBundle app)
      ) enabledApps;
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
          //
            lib.optionalAttrs
              (app.programs.runtimes.browser.enable && app.programs.runtimes.browser.wasmPackage != null)
              {
                "apps.${appName}.browser" = bundled.browser;
              }
        ) enabledApps;
    };
}
