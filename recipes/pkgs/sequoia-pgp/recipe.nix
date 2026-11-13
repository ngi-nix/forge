{
  pkgs,
  config,
  ...
}:

{
  pkgs.sequoia-pgp = {
    version = "1.5.0";
    description = "Command-line OpenPGP tool with post-quantum cryptography support.";
    homePage = "https://sequoia-pgp.org";
    mainProgram = "sq";
    license = "lgpl2Plus";

    source = {
      git = "gitlab:sequoia-pgp/sequoia-sq/sequoia-sq/v1.5.0";
      hash = "sha256-DLJ32QGFbCNcIDZnNAx+JCP7xvL+Qoy3Eju1/xCu/AA=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-mYrDtPE010isOdGpq70sRzB02y9Tiiei0S1McOM4AVM=";
      packages.build = [
        pkgs.pkg-config
        pkgs.rustPlatform.bindgenHook
        pkgs.capnproto
      ];
      packages.run = [
        pkgs.nettle
        pkgs.openssl
        pkgs.sqlite
      ];
    };

    build.extraAttrs = {
      doCheck = false;
    };

    test.script = ''
      sq version 2>&1 | grep 'sq ${config.pkgs.sequoia-pgp.version}'
    '';
  };
}
