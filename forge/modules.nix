{
  inputs,
  lib,
  ...
}:
let
  # A let-binding must be used to be able to both use and export them.
  flakeModules = {
    base.imports = [
      (inputs.import-tree ./modules)

      # Type `flake.modules`
      inputs.flake-parts.flakeModules.modules

      # Convenient aliases to spare recipe authors to write the `flake.modules.` prefix.
      (lib.mkAliasOptionModule [ "apps" ] [ "flake" "modules" "apps" ])
      (lib.mkAliasOptionModule [ "nixos" ] [ "flake" "modules" "nixos" ])
      (lib.mkAliasOptionModule [ "packages" ] [ "flake" "modules" "packages" ])
    ];
    recipes.imports = [
      (inputs.import-tree ../recipes)
    ];
    default.imports = [
      flakeModules.base
      flakeModules.recipes
    ];
  };
in
{
  imports = [
    flakeModules.default
    # Type `flake.flakeModules`
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake = {
    inherit flakeModules;
  };
}
