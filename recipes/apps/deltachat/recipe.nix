{
  pkgs,
  ...
}:

{
  pkgs.deltachat-desktop = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.deltachat-desktop;
    };
  };

  pkgs.deltachat-repl = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.deltachat-repl;
    };
  };

  apps.deltachat = {
    displayName = "Delta Chat";
    description = "Decentralized secure messenger using chatmail relays for Desktop.";
    categories = [ "chat" ];
    usage = ''
      Delta Chat is a reliable, decentralized, and secure instant messaging app. It provides instant creation of private chat profiles using secure and interoperable chatmail relays, offering fast message delivery across multiple devices.

      See also: [Delta Chat FAQ](https://delta.chat/en/help) and [Delta Chat Forums](https://support.delta.chat/).
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Entrust = [
        "DeltaTouch"
        "WebXDC"
      ];
    };

    links = {
      docs = "https://github.com/chatmail/core";
      source = "https://github.com/deltachat/deltachat-desktop";
      website = "https://delta.chat/en/";
    };

    programs = {
      mainPackage = pkgs.deltachat-desktop;
      packages = [
        pkgs.deltachat-desktop
        pkgs.deltachat-repl
      ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
