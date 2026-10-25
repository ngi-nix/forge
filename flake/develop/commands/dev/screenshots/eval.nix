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
      inherit (config) displayName recipePath screenshotSources;
      packages = map (drv: drv.outPath) packages;
      # `toJSON` writes an attribute set with `outPath` as a string, so use other names.
      sources = map (src: {
        path = src.outPath;
        drv = src.drvPath;
      }) sources;
      # Git repositories of the sources, for example from `fetchFromGitHub`.
      repos = builtins.filter builtins.isString (map (src: src.gitRepoUrl or null) sources);
      # Web pages of the application, to find it on Flathub.
      links = builtins.filter builtins.isString (
        [
          config.links.website
          config.links.source
        ]
        ++ map (drv: drv.meta.homepage or null) packages
      );
    };
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = info apps.${name}.config;
  }) names
)
