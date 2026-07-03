{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  # A let-binding must be used to be able to both use and export `flakeModules`.
  flakeModules = {
    base = flakeArgs: {
      imports = [
        modules/lib.nix
        {
          # Expose the `inputs` from `ngi-forge`
          # Note that this `inputs` is always `ngi-forge`'s,
          # even when `flakeModules.base` has been imported in another `flake.nix`.
          _module.args.forge-inputs = inputs;
        }
      ];
      options.perSystem = flake-parts-lib.mkPerSystemOption (
        { system, forge-inputs, ... }:
        {
          imports = [
            # Definitions of options under `forge`.
            modules/apps
            modules/pkgs.nix
            modules/forge.nix
            # Packages building the forge.
            ./packages.nix
          ];

          _module.args.self-inputs = flakeArgs.inputs;
          _module.args.flake-parts-lib = flake-parts-lib;
          _module.args.forge-inputs = inputs;
          _module.args.forge-lib = forge-inputs.self.lib;

          # Do not require users to pin their own `inputs.nixpkgs`.
          _module.args.pkgs = lib.mkDefault forge-inputs.nixpkgs.legacyPackages.${system};
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
