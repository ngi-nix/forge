{
  lib,
  inputs,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
in

{
  imports = [
    ../assertions-warnings.nix
  ];

  options = {
    perSystem = mkPerSystemOption (
      {
        config,
        pkgs,
        nimi,
        system,
        ...
      }:
      let
        cfg = config.forge.apps;
      in
      {
        options = {
          forge = {
            apps = lib.mkOption {
              default = [ ];
              description = "List of applications.";
              type = lib.types.listOf (
                lib.types.submoduleWith {
                  specialArgs = {
                    inherit
                      inputs
                      nimi
                      system
                      ;
                    # Extend pkgs with mypkgs containing all NGI Forge packages
                    # This allows recipes to reference other packages via mypkgs
                    pkgs = pkgs.extend (final: prev: { mypkgs = config.packages; });
                  };
                  modules = [ ./app.nix ];
                }
              );
            };
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

                extend =
                  module:
                  let
                    appExtended = app.result.extend module;
                  in
                  shellBundle appExtended;

                # This is meant to be used in consumer templates.
                #
                # The purpose of it is to only return a recipe module which
                # consumer forges can compose into proper applications.
                #
                # That's why we remove `result`, because it's tied to the
                # providers' aleady generated applications, which can cause
                # conflicts.
                extendRecipe =
                  module: lib.filterAttrsRecursive (name: _: name != "result") (self.extend module).config;
              })
              // lib.optionalAttrs app.programs.runtimes.program.enable {
                program = app.programs.mainPackage;
              }
              // lib.optionalAttrs app.services.runtimes.container.enable {
                container = app.services.runtimes.container.result.build;
              }
              // lib.optionalAttrs app.services.runtimes.nixos.enable {
                vm = app.services.runtimes.nixos.result.build;
                nixosModules.default = {
                  imports =
                    let
                      m = app.services.runtimes.nixos.result.modules;
                    in
                    [
                      m.setup
                      m.nimi
                      m.packages
                      m.extraConfig
                    ];
                };
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
              // lib.optionalAttrs (app.services.runtimes.container.enable && app.services.test.script != null) {
                test-container = app.services.test.result.containerBuild;
              }
              // lib.optionalAttrs (app.services.runtimes.nixos.enable && app.services.test.script != null) {
                test = app.services.test.result.build;
              };

            # finalApp parameter is currently not used in this function
            appPassthru = app: finalApp: mkPassthru app;

            allApps = lib.listToAttrs (
              map (app: {
                name = "${app.name}";
                value = shellBundle app;
              }) cfg
            );
          in
          {
            packages = allApps;

            warnings = lib.flatten (
              map (app: [
                {
                  condition = app.services.components != { } && app.services.test.script == null;
                  message = "App '${app.name}' service test is missing. Use services.test.script option to add a test.";
                }
              ]) cfg
            );
          };
      }
    );
  };
}
