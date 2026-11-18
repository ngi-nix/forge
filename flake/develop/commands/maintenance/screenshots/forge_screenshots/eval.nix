# Applied by `forge-screenshots` to the `apps` output of the flake.
# Returns the data of each application that `forge-screenshots` needs.
apps:
let
  isApp = name: builtins.isAttrs apps.${name} && apps.${name} ? config;
  names = builtins.filter isApp (builtins.attrNames apps);
  # Only fixed-output sources, so that `forge-screenshots` downloads and does not build.
  isSource = src: builtins.isAttrs src && src ? drvPath && src ? outputHash;
  info =
    config:
    let
      packages = config.packages.programs ++ config.packages.services;
      sources = builtins.filter isSource (map (drv: drv.src or null) packages);
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
builtins.listToAttrs (
  map (name: {
    inherit name;
    # Unfree applications are not allowed, and their `config` is replaced with
    # a derivation that warns about it.
    value = if apps.${name}.config ? recipePath then info apps.${name}.config else { unfree = true; };
  }) names
)
