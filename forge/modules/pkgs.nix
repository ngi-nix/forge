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
                Packages indexed by their `pname`.

                Each package uses one of the available builders.
                Only one builder can be enabled per package by setting build.<builder>.enable = true.
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
      # TODO: collect disabled pkgs and print warnings?
      enabledPkgs = lib.filterAttrs (_: pkg: !pkg.broken && !pkg.unfree && pkg.enable) config.forge.pkgs;

      packagesWithNamespace = pkgs.callPackage (forge-lib.flakePackagesWithNamespace {
        namespace = "pkgs";
        derivations = lib.mapAttrs (packageName: package: package.result.derivation) enabledPkgs;
      }) { };
    in
    {
      inherit (packagesWithNamespace) packages;
    };
}
