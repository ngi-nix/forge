{
  pkgs,
  ...
}:

{
  pkgs.rpki-client = {
    version = "9.8-unstable-2026-06-30";
    description = "Port of OpenBSD's rpki-client RPKI relying party validator to other operating systems.";
    homePage = "https://www.rpki-client.org";
    mainProgram = "rpki-client";
    license = "isc";

    source = {
      git = "github:rpki-client/rpki-client-portable/3b63adbdf6646a97a9785e60b96c1fc3365023b8";
      hash = "sha256-QZPnGrNiC/gaPh0JNsoa+E6AOB3rdfJRf2TrZePSv1w=";
    };

    build = {
      extraAttrs = {
        openbsdSrc = pkgs.fetchFromGitHub {
          owner = "rpki-client";
          repo = "rpki-client-openbsd";
          rev = "027566b8e6827a9e280a0ef067464fc2336f0179";
          hash = "sha256-lmyECC4uhBLJb89Gm+oqO4ClkkhFGqGm+cD7GivDqok=";
        };
        configureFlags = [
          "--with-base-dir=/var/cache/rpki-client"
          "--with-output-dir=/var/db/rpki-client"
        ];
        preConfigure = ''
          cp -r $openbsdSrc openbsd
          chmod -R +w openbsd
          ./autogen.sh
        '';
      };
      standardBuilder = {
        enable = true;
        packages.build = [
          pkgs.pkg-config
          pkgs.automake
          pkgs.autoconf
          pkgs.libtool
        ];
        packages.run = [
          pkgs.expat
          pkgs.libressl
          pkgs.rsync
          pkgs.zlib
        ];
      };
    };

    test.script = ''
      rpki-client -V
      rpki-client -n -d /tmp -o /tmp
    '';
  };
}
