{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:
let
  reservedFlakeModuleNames = [
    "base"
    "recipes"
    "default"
  ];

  # One flake-parts module per app, restricting `forge.apps` (and thus
  # `flake.modules.apps`) to only that app. All recipes are still imported
  # (app recipes may depend on packages defined under `recipes/pkgs`, eg.
  # `pkgs.offen` for `recipes/apps/offen`), but only the wanted app's
  # options get evaluated past the `apply` filter below.
  # Use eg. `imports = [ inputs.forge.flakeModules.offen ]` to avoid
  # evaluating every app when only a handful are actually used.
  appFlakeModules =
    let
      appNames = builtins.attrNames (
        lib.filterAttrs (n: t: t == "directory") (builtins.readDir ../recipes/apps)
      );
      colliding = builtins.filter (name: builtins.elem name reservedFlakeModuleNames) appNames;
    in
    assert
      colliding == [ ]
      || throw "app name(s) ${builtins.concatStringsSep ", " colliding} collide with reserved flakeModules names (${builtins.concatStringsSep ", " reservedFlakeModuleNames})";
    lib.genAttrs appNames (
      name: flakeArgs: {
        imports = [
          flakeModules.base
          flakeModules.recipes
          {
            perSystem.options.forge.apps = lib.mkOption {
              apply = lib.filterAttrs (appName: _: appName == name);
            };
          }
        ];
      }
    );

  # A let-binding must be used to be able to both use and export `flakeModules`.
  flakeModules = appFlakeModules // {
    base = flakeArgs: {
      imports = [
        ./modules/lib.nix
        ./modules/apps/flake-modules.nix
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
            ./modules/apps
            ./modules/pkgs.nix
            ./modules/forge.nix
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
