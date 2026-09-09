{
  pkgs,
  config,
  ...
}:

{
  pkgs.reflection.build.identityBuilder = {
    enable = true;
    derivation = pkgs.pkgsOriginal.reflection;
  };

  apps.reflection = {
    displayName = "Reflection";
    description = "Collaborative, p2p, local-first GTK text editor.";
    usage = ''
      Reflection is a collaborative, local-first GTK text editor based on [p2panda](https://p2panda.org/).

      P2Panda provides everything you need to build modern, privacy-respecting and secure local-first applications, using existing libraries like iroh and well-established standards such as BLAKE3, Ed25519, STUN, CBOR, TLS, QUIC.

      If you have access to multiple devices, you can open reflection on both devices and edit the shared documents in real time, collaboratively.

      If you don't have access to multiple devices you can run still test this by launching multiple instances of the desktop application locally using `dbus-run-session`.

      First enter the [nix shell](app/reflection#run-shell), then run two instances like so,

      ```bash
      reflection
      dbus-run-session reflection
      ```

      > [!NOTE]
      > The reflection instance spawned via dbus-run-session command might not work properly for everyone. So prefer testing it on multiple devices if possible.
      >
      > If it works, you should see a warning about using a temporary identity this warning can be safely ignored.
    '';

    links = {
      website = "https://modal.cx/reflection/";
      source = "https://github.com/p2panda/reflection";
      docs = "https://docs.rs/p2panda";
    };

    ngi.grants = {
      Entrust = [ "P2Panda-groups" ];
      Commons = [
        "p2panda-systemservice"
        "Pillow"
      ];
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
