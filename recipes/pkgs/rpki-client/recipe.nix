{
  pkgs,
  ...
}:

{
  pkgs.rpki-client = {
    version = "9.8";
    description = "Port of OpenBSD's rpki-client RPKI relying party validator to other operating systems.";
    homePage = "https://www.rpki-client.org";
    mainProgram = "rpki-client";
    license = "isc";

    source = {
      git = "github:rpki-client/rpki-client-portable/15554f28842d7d9e6cc31eab5f95e36053b42f35";
      hash = "sha256-PejvnEGr+K+g+vLgO+JroZXRAa1LUJUzCwDVm8AyScY=";
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
