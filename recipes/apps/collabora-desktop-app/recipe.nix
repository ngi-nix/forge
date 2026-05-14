{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "collabora-desktop-app";
  displayName = "Collabora Office";
  description = "Collaborative Office for desktop, based on LibreOffice technology.";
  usage = ''
    Collabora Office is a powerful LibreOffice-based office suite that supports all major document, spreadsheet and presentation file formats.
  '';

  icon = ./icon.svg;

  ngi.grants = {
    Commons = [
      "Follow-me-slideshow"
      "InfiniteCanvas"
    ];
    Entrust = [ "LO-Accessible" ];
  };

  links = {
    source = "https://github.com/CollaboraOnline/online";
    website = "https://www.collaboraonline.com/collabora-office/";
  };

  programs = {
    mainPackage = pkgs.collabora-desktop;
    runtimes.program.enable = true;
  };
}
