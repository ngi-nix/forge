{
  pkgs,
  ...
}:

{
  apps.deltachat = {
    displayName = "Delta Chat";
    description = "Decentralized secure messenger using chatmail relays for Desktop.";
    usage = ''
      Delta Chat is a reliable, decentralized, and secure instant messaging app. It provides instant creation of private chat profiles using secure and interoperable chatmail relays, offering fast message delivery across multiple devices.

      Through the **DeltaTauri** project, the desktop application is being ported from Electron to Tauri. This minimizes resource consumption, significantly reduces download sizes, and improves security by relying on the operating system's built-in web view.

      See also: [Delta Chat FAQ](https://delta.chat/en/help) and [Delta Chat Forums](https://support.delta.chat/).
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Entrust = [
        "DeltaTauri"
        "DeltaTouch"
      ];
    };

    links = {
      docs = "https://github.com/chatmail/core";
      source = "https://github.com/deltachat/deltachat-desktop";
      website = "https://delta.chat/en/";
    };

    programs = {
      # Tauri app has some issues so set electron as the default
      mainPackage = pkgs.deltachat-desktop;
      packages = [
        pkgs.deltachat-desktop
        pkgs.deltachat-repl
        pkgs.deltachat-tauri
      ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
