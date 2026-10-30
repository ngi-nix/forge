{
  pkgs,
  ...
}:

{
  pkgs.deltachat-tauri = {
    # TODO: fix package breakage in nixpkgs, see https://github.com/NixOS/nixpkgs/pull/556259
    broken = true;
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.deltachat-tauri;
    };
  };

  apps.deltachat-tauri = {
    # TODO: fix package breakage in nixpkgs, see https://github.com/NixOS/nixpkgs/pull/556259
    broken = true;
    displayName = "Delta Chat (Tauri)";
    description = "Email-based instant messaging for Desktop.";
    categories = [ "chat" ];
    usage = ''
      Delta Chat is a reliable, decentralized, and secure instant messaging app. It provides instant creation of private chat profiles using secure and interoperable chatmail relays, offering fast message delivery across multiple devices.

      Through the **DeltaTauri** project, the desktop application is being ported from Electron to Tauri. This minimizes resource consumption, significantly reduces download sizes, and improves security by relying on the operating system's built-in web view.

      See also: [Delta Chat FAQ](https://delta.chat/en/help) and [Delta Chat Forums](https://support.delta.chat/).
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Entrust = [
        "DeltaTauri"
      ];
    };

    links = {
      docs = "https://github.com/chatmail/core";
      source = "https://github.com/deltachat/deltachat-tauri";
      website = "https://github.com/deltachat/deltachat-tauri";
    };

    programs = {
      mainPackage = pkgs.deltachat-tauri;
      packages = [
        pkgs.deltachat-tauri
      ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
