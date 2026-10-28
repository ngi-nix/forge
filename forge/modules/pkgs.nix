{
  config,
  lib,
  forge-lib,
  packageBuilderModule,
  pkgs,
  ...
}:
{
  imports = [
    ./builders/shared
  ];

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
                  specialArgs = (builtins.removeAttrs specialArgs [ "pkgs" ]) // {
                    defaultPkgs = specialArgs.pkgs;
                    enable = forgeArgs.config.enable;
                    forgeOptions = forgeArgs.options;
                    inherit packageBuilderModule;
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
      packagesWithNamespace = pkgs.callPackage (forge-lib.flakePackagesWithNamespace {
        namespace = "pkgs";
        derivations = lib.mapAttrs (packageName: package: package.result.derivation) (
          lib.filterAttrs (_: pkg: !pkg.broken && pkg.enable) config.forge.pkgs
        );
      }) { };
    in
    {
      inherit (packagesWithNamespace) packages;
    };
}
