{
  lib,
  pkgs,
  ...
}:

{
  pkgs.kaidan = {
    build.identityBuilder = {
      enable = true;
      # TODO: use `pkgs.pkgsOriginal.kaidan` after this propagates:
      # https://github.com/NixOS/nixpkgs/pull/495112
      derivation = pkgs.callPackage ./_kaidan.nix { };
    };
  };

  apps.kaidan = {
    displayName = "Kaidan";
    description = "User-friendly and modern chat app, using XMPP.";
    categories = with lib.categories; [ Chat ];
    usage = ''
      Kaidan is a user-friendly and modern chat app for every device.

      It uses the open communication protocol XMPP (Jabber).
      Unlike other chat apps, you are not dependent on one specific service provider.

      Kaidan does not have all basic features yet and has still some stability issues.
      Current features include audio messages, video messages, and file sharing.
    '';

    links = {
      website = "https://www.kaidan.im";
      source = "https://invent.kde.org/network/kaidan";
      docs = null;
    };

    ngi.grants = {
      Commons = [
        "Kaidan-MUC"
      ];
      Review = [
        "Kaidan"
        "Kaidan-Groups"
        "Kaidan-AV"
        "Kaidan-Mediasharing"
      ];
      Entrust = [
        "Kaidan-Auth"
      ];
    };

    programs = {
      mainPackage = pkgs.kaidan;
      packages = [ pkgs.kaidan ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };
  };
}
