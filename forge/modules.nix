{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  # A let-binding must be used to be able to both use and export `flakeModules`.
  flakeModules = {
    base = {
      options.perSystem = flake-parts-lib.mkPerSystemOption (
        { system, ... }:
        {
          imports = [
            # Definitions of options under `forge`.
            modules/apps/default.nix
            modules/packages.nix
            modules/forge.nix
            # Packages building the forge.
            ./packages.nix
          ];

          # Workaround flake-parts exposing only `inputs'`
          # and forbidding `inputs` in `perSystem`,
          # but we need access to `inputs.ngi-forge.inputs`.
          _module.args.flakeInputs = inputs;

          # Do not require users to pin their own `inputs.nixpkgs`.
          _module.args.pkgs = lib.mkDefault (inputs.ngi-forge.inputs.nixpkgs.legacyPackages.${system});
        }
      );
    };
    recipes = {
      options.perSystem = flake-parts-lib.mkPerSystemOption {
        forge = inputs.import-tree ../recipes;
      };
    };
    # By default ngi-forge's recipes are included,
    # users not interested in them must only import `flakeModules.base` instead.
    default.imports = [
      flakeModules.base
      flakeModules.recipes
    ];
  };
in
{
  imports = [
    # `flake.flakeModules` :: lazyAttrsOf deferredModule
    # are modules to generate outputs of a flake.nix
    inputs.flake-parts.flakeModules.flakeModules
    flakeModules.default
  ];
  flake = {
    inherit flakeModules;
  };
}
