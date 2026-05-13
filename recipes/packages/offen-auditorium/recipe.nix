{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Analytics UI for Offen.";

  inherit (systemConfig.forge.packages.offen)
    homePage
    license
    source
    version
    ;

  build.pnpmPackageBuilder = {
    enable = true;
    pnpmDepsHash = "sha256-xpdFlgHBUcHgL16hruFg6Spv1IlBEc7PB/UqpKnv5Oo=";
    sourceRoot = "source/auditorium";
    buildScript = "build";
    installDir = "dist";
  };

  build.extraAttrs = {
    preBuild = ''
      cp -r ../locales locales
    '';
  };
}
