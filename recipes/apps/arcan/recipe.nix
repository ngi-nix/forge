{
  pkgs,
  ...
}:

{
  apps.arcan = {
    displayName = "Arcan";
    description = "Explorative p2p protocol for fast and secure remote desktops.";
    usage = ''
      Arcan is a combined display server, multimedia framework and game engine that
      also includes an explorative p2p protocol for fast and secure remote desktops.

      Start the Arcan display server

      ```bash
      arcan
      ```
    '';

    links = {
      website = "https://arcan-fe.com";
      source = "https://github.com/letoram/arcan";
      docs = "https://github.com/letoram/arcan/wiki";
    };

    ngi.grants = {
      Core = [
        "Arcan-A12-directory"
        "Arcan-A12-tools"
      ];
      Entrust = [
        "Arcan-A12"
      ];
      Commons = [ "Arcan-A12-endpoints" ];
    };

    programs = {
      packages = [
        pkgs.arcan
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs = {
      packages = [ pkgs.xvfb-run ];
      script = ''
        xvfb-run arcan --version 2>&1 | grep "Xorg running"
      '';
    };
  };
}
