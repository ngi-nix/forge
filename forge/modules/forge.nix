{
  inputs,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
  recipeRootType =
    with lib.types;
    listOf (
      unique { message = "recipe root paths must be unique to not load the same recipe twice"; } path
    );
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
            apps = lib.mkOption {
              type = recipeRootType;
              defaultText = lib.literalExpression ''[ (inputs.ngi-forge + "/recipes/apps") ]'';
              description = ''
                Directories containing app recipe files.
                Each recipe should be a recipe.nix file in a subdirectory
                (e.g., recipes/apps/my-app/recipe.nix).

                Set to the empty list to disable automatic app recipe loading.
              '';
              example = lib.literalExpression "[ recipes/apps ]";
            };
            packages = lib.mkOption {
              type = recipeRootType;
              defaultText = lib.literalExpression ''[ (inputs.ngi-forge + "/recipes/packages") ]'';
              description = ''
                Directories containing package recipe files.
                Each recipe should be a recipe.nix file in a subdirectory
                (e.g., recipes/packages/hello/recipe.nix).

                Set to the empty list to disable automatic package recipe loading.
              '';
              example = lib.literalExpression "[ recipes/packages ]";
            };
          };
        };

        config = {
          forge.recipeDirs.apps = [ (inputs.ngi-forge + "/recipes/apps") ];
          forge.recipeDirs.packages = [ (inputs.ngi-forge + "/recipes/packages") ];
          forge.apps = lib.mkMerge (map inputs.ngi-forge.lib.loadRecipes config.forge.recipeDirs.apps);
          forge.packages = lib.mkMerge (
            map inputs.ngi-forge.lib.loadRecipes config.forge.recipeDirs.packages
          );
        };
      }
    );
  };

  config = {
    flake.lib = {
      # Helper to load recipes from a directory using import-tree
      loadRecipes =
        recipeRoot:
        let
          recipeFileToModule =
            recipePath:
            let
              recipeName = lib.baseNameOf (lib.dirOf recipePath);
            in
            # Nix requires to remove the context of a string having one,
            # when using it has an attribute name,
            # and `recipeName` can inherit such context, eg. when `recipeRoot` is a `path/to/dir`.
            # `recipePath` safely keeps any context it may have.
            lib.nameValuePair (builtins.unsafeDiscardStringContext recipeName) {
              imports = [ (lib.setDefaultModuleLocation recipePath recipePath) ];
              config = {
                inherit recipePath;
              };
            };
        in
        lib.pipe inputs.ngi-forge.inputs.import-tree [
          (i: i.initFilter (lib.hasSuffix "/recipe.nix"))
          (i: i.withLib lib)
          (i: i.leafs recipeRoot)
          (map recipeFileToModule)
          lib.listToAttrs
        ];
    };
  };
}
