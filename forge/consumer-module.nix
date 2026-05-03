# consume and extend a forge provider

{ provider }:

{
  lib,
  self,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;

  rootPath = self.outPath;
in

{
  # core forge modules
  imports = [
    (provider + "/forge/modules/forge.nix")
    (provider + "/forge/modules/apps")
    (provider + "/forge/modules/packages.nix")
  ];

  options.perSystem = mkPerSystemOption (
    { options, ... }:
    {
      options.forge.provider.packages = lib.mkOption {
        internal = true;
        type = options.forge.packages.type;
        default = { };
        description = "";
      };

      options.forge.provider.apps = lib.mkOption {
        internal = true;
        type = options.forge.apps.type;
        default = { };
        description = "";
      };

      options.forge.consumer.packages = lib.mkOption {
        internal = true;
        type = options.forge.packages.type;
        default = { };
        description = "";
      };

      options.forge.consumer.apps = lib.mkOption {
        internal = true;
        type = options.forge.apps.type;
        default = { };
        description = "";
      };
    }
  );

  config = {
    # Override the inputs argument for submodules with nix-forge's inputs
    # This ensures modules have access to nix-utils and import-tree
    _module.args.inputs = lib.mkForce provider.inputs;

    perSystem =
      {
        system,
        config,
        lib,
        ...
      }:

      let
        appSuffix = "-app";

        # Load recipe files from a directory using import-tree
        # Returns a list of modules, each containing a recipe config and file path
        loadRecipesFromDir =
          dir:
          if dir == null then
            [ ]
          else
            let
              # Convert string path to actual path relative to flake root
              dirPath = rootPath + "/${dir}";

              recipeFiles = lib.pipe dirPath [
                # Use bundled import-tree from nix-forge inputs
                (provider.inputs.import-tree.withLib lib).leafs
                # Exclude non-recipe files
                (lib.filter (file: lib.hasSuffix "/recipe.nix" file))
              ];
            in
            lib.listToAttrs (
              map (
                recipeFile:
                let
                  recipeName = lib.head (lib.match "^.*/([^/]*)/recipe.nix$" recipeFile);
                in
                lib.nameValuePair recipeName {
                  imports = [ recipeFile ];
                  config = {
                    name = recipeName;
                    recipePath = lib.removePrefix (rootPath + "/") recipeFile;
                  };
                }
              ) recipeFiles
            );

        # Load package and app recipes from configured directories
        consumerPackageRecipes = loadRecipesFromDir config.forge.recipeDirs.packages;
        consumerAppRecipes = loadRecipesFromDir config.forge.recipeDirs.apps;

        # Get app and package derivations from provider
        apps = lib.pipe provider.packages.${system} [
          (lib.filterAttrs (name: app: lib.hasSuffix appSuffix name))
        ];

        packages = lib.pipe provider.packages.${system} [
          (lib.filterAttrs (name: pkg: (!lib.hasSuffix appSuffix name) && (pkg ? config)))
        ];

        # Filter out internal `result` attributes from config to avoid conflicts
        cleanConfig = config: lib.filterAttrsRecursive (name: _: name != "result") config;

        loadConfig = attrs: lib.mapAttrs (name: drv: cleanConfig (drv.config or { })) attrs;

        providerAppConfigs = loadConfig apps;
        providerPackageConfigs = loadConfig packages;

        # Merge provider and consumer recipes
        mergeRecipes =
          type:
          lib.mapAttrs (
            providerName: providerItem:
            let
              consumerRecipe = config.forge.consumer.${type}.${providerName} or null;

              providerRecipe = cleanConfig providerItem;
            in
            if consumerRecipe != null then
              {
                imports = [
                  (rootPath + "/" + consumerRecipe.recipePath)
                  providerRecipe
                ];
              }
            else
              providerRecipe
          ) config.forge.provider."${type}";

        mergedApps = mergeRecipes "apps";
        mergedPackages = mergeRecipes "packages";
      in

      {
        forge.provider.packages = providerPackageConfigs;
        forge.provider.apps = providerAppConfigs;

        forge.consumer.packages = consumerPackageRecipes;
        forge.consumer.apps = consumerAppRecipes;

        forge.apps = mergedApps;
        forge.packages = mergedPackages;
      };
  };
}
