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
      git = "github:rpki-client/rpki-client-portable/9.8";
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
          pkgs.zlib
        ];
      };
    };

    phases = {
      configure.script.pre = ''
        cp -r $openbsdSrc openbsd
        chmod -R +w openbsd
        ./autogen.sh
      '';
      check.packages.build.host = [
        pkgs.rsync
      ];
      configure.flags = [
        "--with-base-dir=/var/cache/rpki-client"
        "--with-output-dir=/var/db/rpki-client"
      ];
    };

    # Warning(reproducibility): `tests.script` being run in a fixed-output derivation,
    # it must not be built with nix's `sandbox=relaxed` otherwise files will be written in the host's `/tmp`
    # and that may cause subsequent builds to fail by being unable to overwrite those files:
    # > rpki-client-test-salted-cbnxqbrzn1rb> rpki-client: finish for openbgpd format failed: Operation not permitted
    # > rpki-client-test-salted-cbnxqbrzn1rb> rpki-client: finish for rpki.ccr format failed: Operation not permitted
    test.script = ''
      rpki-client -V
      rpki-client -n -d /tmp -o /tmp
    '';
  };
}
