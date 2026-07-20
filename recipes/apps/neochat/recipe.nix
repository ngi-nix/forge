{
  pkgs,
  ...
}:

{
  apps.neochat = {
    displayName = "NeoChat";
    description = "A client for Matrix, the decentralized communication protocol.";
    usage = ''
      NeoChat is a visually appealing, elegant, and feature-rich Matrix client designed to look and work great on desktop and mobile.
      It is part of the KDE ecosystem, providing a native experience with seamless integration.
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Review = [ "NeoChat" ];
    };

    links = {
      website = "https://apps.kde.org/nl/neochat";
      source = "https://invent.kde.org/network/neochat";
    };

    programs = {
      mainPackage = pkgs.kdePackages.neochat;
      runtimes.program.enable = true;
    };
  };
}
