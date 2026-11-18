# Applied by `forge-screenshots` to the `apps` output of the flake.
# Returns the data of each application that `forge-screenshots` needs.
apps:
let
  inherit (builtins)
    attrNames
    filter
    isAttrs
    listToAttrs
    ;

  # The `apps` output also has other attributes, for example `system`.
  isApp = name: apps.${name}.forge._recipeType or null == "apps";
  names = filter isApp (attrNames apps);
  # Only fixed-output sources, so that `forge-screenshots` downloads and does not build.
  isSource = src: isAttrs src && src ? drvPath && src ? outputHash;
  info =
    config:
    let
      packages = config.packages.programs ++ config.packages.services;
      sources = filter isSource (map (drv: drv.src or null) packages);
    in
    {
      inherit (config) recipePath;
      packages = map (drv: drv.outPath) packages;
      # `toJSON` writes an attribute set with `outPath` as a string, so use other names.
      sources = map (src: {
        path = src.outPath;
        drv = src.drvPath;
        # The Git repository and the revision of the source, for example from
        # `fetchFromGitHub`, to pin the screenshot URLs to the revision.
        gitRepoUrl = src.gitRepoUrl or null;
        rev = src.rev or null;
      }) sources;
    };
in
listToAttrs (
  map (name: {
    inherit name;
    # The flake does not allow unfree applications, and their `config` is
    # replaced with a derivation that warns about it.
    value = if apps.${name}.forge.unfree then { unfree = true; } else info apps.${name}.config;
  }) names
)
