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
            options.pkgs = lib.mkOption {
              default = { };
              description = ''
                Packages indexed by their attribute names.

                Each package uses one of the available builders.
                Only one builder can be enabled per package by setting `build.builders.''${builder}.enable = true`.
              '';
              type = lib.types.attrsOf (
                lib.types.submoduleWith {
                  specialArgs = specialArgs // {
                    enable = forgeArgs.config.enable;
                    forgeOptions = forgeArgs.options;
                  };
                  modules = [
                    ./pkgs/pkg.nix
                  ];
                }
              );
            };
          }
        )
      ];
    };
  };

  # Config section is now provided by builder modules
  config =
    let
      enabledPkgs = lib.filterAttrs (_: pkg: !pkg.broken && pkg.enable) config.forge.pkgs;

      handleUnfree = forge-lib.handleUnfree pkgs;

      scopedPkgs = forge-lib.scopeAttrs {
        type = "pkgs";
        values = lib.mapAttrs (_packageName: handleUnfree) enabledPkgs;
      };

      packagesWithNamespace = pkgs.callPackage (forge-lib.flakePackagesWithNamespace {
        namespace = "pkgs";
        derivations = scopedPkgs;
      }) { };
    in
    {
      inherit (packagesWithNamespace) packages;
    };
}
