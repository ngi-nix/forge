{
  config,
  lib,
  name,
  specialArgs,
  ...
}:
{
  options = {
    # This internal option allows us to share this exact same logic
    # between apps and packages by dynamically accessing `specialArgs.forgeOptions.${config._recipeType}`
    _recipeType = lib.mkOption {
      type = lib.types.enum [
        "apps"
        "pkgs"
      ];
      internal = true;
      description = "Internal type to distinguish between apps and pkgs for metadata resolution.";
    };

    recipePath = lib.mkOption {
      type = lib.types.str;
      default =
        let
          locs = map (
            def: builtins.unsafeGetAttrPos name def.value
          ) specialArgs.forgeOptions.${config._recipeType}.definitionsWithLocations;
          validLocs = builtins.filter (loc: loc != null) locs;
          # An app or package can have multiple files defining attributes (e.g. `screenshots.nix`),
          # but prioritize `recipe.nix` if present
          recipeLocs = builtins.filter (loc: builtins.baseNameOf loc.file == "recipe.nix") validLocs;
          absPath =
            if recipeLocs != [ ] then
              (builtins.head recipeLocs).file
            else if validLocs != [ ] then
              (builtins.head validLocs).file
            else
              "";
        in
        if absPath == "" then
          ""
        else
          let
            match = builtins.match "^/nix/store/[a-z0-9]+-[^/]+/(.*)$" absPath;
          in
          if match != null then builtins.head match else absPath;
      internal = true;
      description = "Relative file path pointing to the recipe definition.";
    };
  };
}
