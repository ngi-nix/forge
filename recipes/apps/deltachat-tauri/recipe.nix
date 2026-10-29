{
  config,
  pkgs,
  ...
}:

{
  pkgs.deltachat-tauri = {
    # TODO: fix package breakage in nixpkgs, see https://github.com/NixOS/nixpkgs/pull/556259
    nixpkgsPin = config.apps.deltachat-tauri.nixpkgsPin;
    build.identityBuilder = {
      enable = true;
      derivation = p: p.deltachat-tauri;
    };
  };

  apps.deltachat-tauri = {
    # TODO: fix package breakage in nixpkgs, see https://github.com/NixOS/nixpkgs/pull/556259
    displayName = "Delta Chat (Tauri)";
    description = "Email-based instant messaging for Desktop.";
    usage = ''
      Delta Chat is a reliable, decentralized, and secure instant messaging app. It provides instant creation of private chat profiles using secure and interoperable chatmail relays, offering fast message delivery across multiple devices.

      Through the **DeltaTauri** project, the desktop application is being ported from Electron to Tauri. This minimizes resource consumption, significantly reduces download sizes, and improves security by relying on the operating system's built-in web view.

      See also: [Delta Chat FAQ](https://delta.chat/en/help) and [Delta Chat Forums](https://support.delta.chat/).
    '';

    # Pinned to the last working Nixpkgs revision on Hydra (build 343722082, 2.59.0)
    # Upstream breakage introduced in https://github.com/NixOS/nixpkgs/pull/556259
    nixpkgsPin = {
      rev = "9fbb54b33e91ee4ca368e35a78e0613c720600b3";
      narHash = "sha256-cV5xEJJK3BvhU8rEd4mC9UsmDi5qscv/kzGPhBRC5WA=";
      date = "2026-08-26";
      reason = "This package is broken on latest nixos-unstable; we are pinning to last working version from nixpkgs";
    };

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
      mainPackage = pkgs: pkgs.deltachat-tauri;
      packages = pkgs: [
        pkgs.deltachat-tauri
      ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
