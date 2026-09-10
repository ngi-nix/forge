{
  pkgs,
  ...
}:

{
  pkgs.rpki-client = {
    version = "9.9";
    description = "Port of OpenBSD's rpki-client RPKI relying party validator to other operating systems.";
    homePage = "https://www.rpki-client.org";
    mainProgram = "rpki-client";
    license = "isc";

    source = {
      git = "github:rpki-client/rpki-client-portable/9.9";
      hash = "sha256-YYEz2F0R15Fr+eYO9RIXW8+BOh3sJA7acmN1d4ka0ns=";
    };

    build = {
      extraAttrs = {
        # IMPORTANT:
        # rpki-client-openbsd needs to be updated along with rpki-client to the
        # version matching rpki-client release date.
        openbsdSrc = pkgs.fetchFromGitHub {
          owner = "rpki-client";
          repo = "rpki-client-openbsd";
          rev = "65b0882149d7c1a22208b0415b9ece507d8f9522";
          hash = "sha256-SVAe68oVTuQHcVD+KbbRPm0wNrrV4kc8VG20a1BUZ1w=";
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
