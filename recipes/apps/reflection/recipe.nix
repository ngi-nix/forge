{
  pkgs,
  config,
  ...
}:

{
  apps.reflection = {
    displayName = "Reflection";
    description = "p2p collaborative, local-first GTK text editor.";
    usage = ''
      Reflection is a collaborative, local-first GTK text editor based on [p2panda](https://p2panda.org/).

      P2Panda provides everything you need to build modern, privacy-respecting and secure local-first applications, using existing libraries like iroh and well-established standards such as BLAKE3, Ed25519, STUN, CBOR, TLS, QUIC.

      You can run multipe instances of the desktop application to test the p2p text collaboration locally using `dbus-run-session`.

      First enter the [nix shell](app/reflection#run-shell), then run two instances like so,

      ```bash
      reflection & dbus-run-session reflection
      ```
    '';

    links = {
      website = "https://modal.cx/reflection/";
      source = "https://github.com/p2panda/reflection";
      docs = "https://docs.rs/p2panda";
    };

    ngi.grants = {
      Entrust = [ "P2Panda-groups" ];
      Commons = [ "p2panda-systemservice" ];
      Review = [ "P2Panda" ];
    };

    icon = ./icon.svg;

    programs = {
      mainPackage = pkgs.reflection;
      packages = [ pkgs.reflection ];

      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.packages = [
      pkgs.writableTmpDirAsHomeHook
      pkgs.xvfb-run
    ];
    test.programs.script = ''
      xvfb-run reflection --help | grep -iq reflection
    '';
  };
}
