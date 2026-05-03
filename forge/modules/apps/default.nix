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
        cfg = config.forge;
      in
      {
        options = {
          forge = {
            apps = lib.mkOption {
              default = { };
              description = "List of applications.";
              type = lib.types.attrsOf (
                lib.types.submoduleWith {
                  specialArgs = {
                    rootConfig = config;
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
              // lib.optionalAttrs app.services.runtimes.container.enable {
                container = app.services.runtimes.container.result.build;
              }
              // lib.optionalAttrs app.services.runtimes.nixos.enable {
                vm = app.services.runtimes.nixos.result.build;
                nixos = {
                  modules = app.services.runtimes.nixos.result.modules;
                  vm = app.services.runtimes.nixos.result.build;
                };
              }
              // lib.optionalAttrs (app.services.runtimes.nixos.enable && app.test.script != "") {
                test = app.test.result.build;
              }
              // lib.optionalAttrs (app.services.runtimes.container.enable && app.test.script != "") {
                test-container = app.test.result.containerBuild;
              };

            # finalApp parameter is currently not used in this function
            appPassthru = app: finalApp: mkPassthru app;

            allApps = lib.mapAttrs (name: app: shellBundle app) cfg.apps;
          in
          {
            packages = allApps;
          };
      }
    );
  };
}
