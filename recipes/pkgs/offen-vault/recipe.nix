{
  config,
  ...
}:

{
  pkgs.offen-vault = {
    description = "Client-side encryption vault for Offen.";
    inherit (config.pkgs.offen)
      source
      version
      homePage
      license
      ;

    build.pnpmPackageBuilder = {
      enable = true;
      pnpmDepsHash = "sha256-vAXHm85rlsG0pAeRmqzmmI+Ztw0CmkzgVg9f67m3S3g=";
      buildScript = "build";
      installDir = "dist";
    };

    phases = {
      unpack.sourceRoot = "source/vault";
      build.script.pre = ''
        cp -r ../locales locales
      '';
    };
  };
}
