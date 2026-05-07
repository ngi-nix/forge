{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Client-side analytics script for Offen.";

  inherit (systemConfig.forge.packages.offen)
    homePage
    license
    source
    version
    ;

  build.pnpmPackageBuilder = {
    enable = true;
    pnpmDepsHash = "sha256-Vmv4aESpAvE9Dg28WpSPhtEEBr8q/BfqrJl5EXC0nl4=";
    sourceRoot = "source/script";
    buildScript = "build";
    installDir = "dist";
  };

  build.extraAttrs = {
    preBuild = ''
      cp -r ../locales locales
    '';
  };
}
