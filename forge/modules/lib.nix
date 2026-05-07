{
  inputs,
  lib,
  ...
}:
{
  config = {
    flake.lib = {
      # Helper to load recipes from a directory using `import-tree`
      loadRecipes = # :: { rootDir; sourceUrl } -> attrsOf submodule
        {
          rootDir, # :: Path
          # Root directory containing `recipe.nix` files to load.
          sourceUrl, # :: { path :: Path } -> URL
          # Function to generate an URL to the `recipe.nix` file
          # given the `path` to the `recipe.nix` file relative to `rootDir`.
        }:
        let
          recipeFileToModule =
            recipeFile:
            let
              recipeName = lib.baseNameOf (lib.dirOf recipeFile);
            in
            # Nix requires to remove the context of a string having one,
            # when using it has an attribute name,
            # and `recipeName` can inherit such context, eg. when `rootDir` is a `path/to/dir`.
            # `recipeFile` safely keeps any context it may have.
            lib.nameValuePair (builtins.unsafeDiscardStringContext recipeName) {
              imports = [ (lib.setDefaultModuleLocation recipeFile recipeFile) ];
              config = {
                recipeUrl = sourceUrl {
                  path = lib.pipe recipeFile [
                    toString
                    (lib.removePrefix (toString rootDir))
                    (lib.removePrefix "/")
                  ];
                };
              };
            };
        in
        lib.pipe inputs.ngi-forge.inputs.import-tree [
          (i: i.initFilter (lib.hasSuffix "/recipe.nix"))
          (i: i.withLib lib)
          (i: i.leafs rootDir)
          (map recipeFileToModule)
          lib.listToAttrs
        ];
      # `sourceInfoRef input` returns the a commit reference of the given `input`
      # or some approximation.
      sourceInfoRef =
        input:
        if input.sourceInfo ? "shortRev" then
          input.sourceInfo.shortRev
        else if input.sourceInfo ? "dirtyShortRev" then
          lib.removeSuffix "-dirty" input.sourceInfo.dirtyShortRev
        else if input.sourceInfo ? "rev" then
          input.sourceInfo.rev
        else
          "@";
    };
  };
}
