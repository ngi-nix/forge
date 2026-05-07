{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Client-side encryption vault for Offen.";

  inherit (systemConfig.forge.packages.offen)
    homePage
    license
    source
    version
    ;

  build.pnpmPackageBuilder = {
    enable = true;
    pnpmDepsHash = "sha256-vAXHm85rlsG0pAeRmqzmmI+Ztw0CmkzgVg9f67m3S3g=";
    sourceRoot = "source/vault";
    buildScript = "build";
    installDir = "dist";
  };

  build.extraAttrs = {
    preBuild = ''
      cp -r ../locales locales
    '';
  };
}
