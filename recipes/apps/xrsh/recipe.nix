{
  pkgs,
  ...
}:

{
  apps.xrsh = {
    displayName = "xrsh";
    description = "Interactive text/OS terminal inside WebXR.";
    usage = ''
      xrsh is a terminal emulator and Linux ISO launcher that runs inside a WebXR
      environment, enabling REPLs and interactive sessions in virtual reality.

      Launch xrsh

      ```bash
      xrsh
      ```
    '';

    links = {
      website = "https://xrsh.isvery.ninja";
      source = "https://forgejo.isvery.ninja/xrsh/xrsh";
    };

    ngi.grants = {
      Entrust = [
        "xrsh"
      ];
    };

    programs = {
      packages = [
        pkgs.xrsh
      ];

      runtimes.shell = {
        enable = true;
      };
    };
  };
}
