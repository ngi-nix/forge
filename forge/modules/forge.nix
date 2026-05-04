{
  inputs,
  self,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
    perSystem = mkPerSystemOption (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        options.forge = {
          repositoryUrl = lib.mkOption {
            type = lib.types.str;
            default = "github:ngi-nix/forge";
            description = ''
              NGI Forge repository URL.
            '';
            example = "github:ngi-nix/forge";
          };

          recipeDirs = {
            packages = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "recipes/packages";
              description = ''
                Directory containing package recipe files.
                Each recipe should be a recipe.nix file in a subdirectory
                (e.g., recipes/packages/hello/recipe.nix).

                Set to null to disable automatic package recipe loading.
              '';
              example = "recipes/packages";
            };

            apps = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "recipes/apps";
              description = ''
                Directory containing app recipe files.
                Each recipe should be a recipe.nix file in a subdirectory
                (e.g., recipes/apps/my-app/recipe.nix).

                Set to null to disable automatic app recipe loading.
              '';
              example = "recipes/apps";
            };
          };
        };

        config = {
          # Remark(reusability): `self` is used as `rootDir`,
          # meaning that it could me the user's own `self`,
          # not necessarily `ngi-forge`'s.
          forge.packages = inputs.ngi-forge.lib.loadRecipes {
            rootDir = self.outPath;
            dir = config.forge.recipeDirs.packages;
          };
          forge.apps = inputs.ngi-forge.lib.loadRecipes {
            rootDir = self.outPath;
            dir = config.forge.recipeDirs.apps;
          };
        };
      }
    );
  };

  config = {
    flake.lib = {
      # Helper to load recipes from a directory using import-tree
      loadRecipes =
        { rootDir, dir }:
        if dir == null then
          [ ]
        else
          let
            # Convert string path to actual path relative to flake root
            # self.outPath gives us the flake root directory
            dirPath = rootDir + "/${dir}";

            recipeFiles = lib.pipe dirPath [
              (inputs.ngi-forge.inputs.import-tree.withLib lib).leafs
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
                  recipePath = lib.removePrefix (rootDir + "/") recipeFile;
                };
              }
            ) recipeFiles
          );
    };
  };
}
