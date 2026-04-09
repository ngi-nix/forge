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
                    # Extend pkgs with mypkgs containing all Nix Forge packages
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
                  paths = lib.flatten (lib.mapAttrsToList (name: value: value.requirements) app.programs.components);
                };
              in
              # Passthru
              appDrv.overrideAttrs (_: {
                passthru = appPassthru app appDrv;
              });

            mkPassthru =
              app:
              {
                config = app;
                extend =
                  module:
                  let
                    appExtended = app.result.extend module;
                  in
                  shellBundle appExtended;
              }
              // lib.optionalAttrs (app.test.script != "") { test = app.test.result.build; }
              // lib.optionalAttrs app.services.runtimes.container.enable {
                container = app.services.runtimes.container.result.imageBuilder;
              }
              // lib.optionalAttrs app.services.runtimes.nixos.enable {
                vm = app.services.runtimes.nixos.result.build;
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
          };
      }
    );
  };
}
