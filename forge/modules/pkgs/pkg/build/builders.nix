{ lib, ... }:
{
  # Builders are currently setting values in their ancestors,
  # hence they cannot be imported nested in a submodule.
  imports = [
    builders/beam.nix
    builders/go.nix
    builders/identity.nix
    builders/npm.nix
    builders/ocaml.nix
    builders/pnpm.nix
    builders/python.nix
    builders/rust.nix
    builders/standard.nix
  ];
  options.build = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        # For each builder
        ({ specialArgs, config, ... }: {
          options.builders = lib.mkOption {
            description = "Package builders.";
            default = { };
            type = lib.types.submoduleWith {
              inherit specialArgs;
              modules = [
              ];
            };
          };
        })
      ];
    };
  };
}
