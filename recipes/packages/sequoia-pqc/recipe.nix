{
  pkgs,
  packages,
  ...
}:

{
  packages.sequoia-pqc = {
    version = "1.4.0-pqc.1";
    description = "Command-line OpenPGP tool with post-quantum cryptography support.";
    homePage = "https://sequoia-pgp.org";
    mainProgram = "sq";
    license = "lgpl2Plus";

    source = {
      git = "gitlab:sequoia-pgp/sequoia-sq/v1.4.0-pqc.1";
      hash = "sha256-ep3il5In0ecyNWHvCo0yh4yL92VTy3/FligzKkY+SJQ=";
    };

    build.rustPackageBuilder = {
      enable = true;
      cargoHash = "sha256-NYUYQCKG4XWchvuEzzAD+R25Wk0YrHN4ISVtQnhPkcM=";
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
      sq version 2>&1 | grep 'sq ${packages.sequoia-pqc.version}'
    '';
  };
}
