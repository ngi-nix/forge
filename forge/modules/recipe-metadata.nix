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
        "packages"
      ];
      internal = true;
      description = "Internal type to distinguish between apps and packages for metadata resolution.";
    };

    recipePath = lib.mkOption {
      type = lib.types.str;
      default =
        let
          locs = builtins.map (
            def: builtins.unsafeGetAttrPos name def.value
          ) specialArgs.forgeOptions.${config._recipeType}.definitionsWithLocations;
          validLocs = builtins.filter (loc: loc != null) locs;
          absPath = if validLocs != [ ] then (builtins.head validLocs).file else "";
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
