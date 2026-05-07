{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "IronCalc server package";

  inherit (systemConfig.forge.packages.ironcalc)
    homePage
    license
    source
    version
    ;

  build.rustPackageBuilder = {
    enable = true;
    cargoHash = "sha256-46IwZJI9AOs+IQFbfz89A2yIi5db7rVMVNsO9W+tn+c=";
    packages.build = [
      pkgs.pkg-config
    ];
    packages.run = [
      pkgs.bzip2
      pkgs.zstd
    ];
  };

  build.extraAttrs = {
    strictDeps = true;
    __structuredAttrs = true;
    cargoRoot = "webapp/app.ironcalc.com/server";
    buildAndTestSubdir = "webapp/app.ironcalc.com/server";
    postInstall = ''
      install -Dm644 webapp/app.ironcalc.com/server/init_db.sql $out/share/ironcalc/init_db.sql
    '';
  };
}
