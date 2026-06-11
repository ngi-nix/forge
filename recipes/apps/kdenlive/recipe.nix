{
  pkgs,
  ...
}:

{
  apps.kdenlive = {
    displayName = "Kdenlive";
    description = "Free and open source video editor, based on MLT Framework and KDE Frameworks.";
    usage = ''
      Kdenlive is a powerful, free and open-source video editor that brings professional-grade video editing capabilities to everyone. Whether you're creating a simple family video or working on a complex project, Kdenlive provides the tools you need to bring your vision to life.

      For more information about Kdenlive's features, tutorials, and community, please visit the [official website](https://kdenlive.org).
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [ "Kdenlive" ];
    };

    links = {
      website = "https://kdenlive.org";
      docs = "https://docs.kdenlive.org/en/index.html";
      source = "https://invent.kde.org/multimedia/kdenlive";
    };

    programs = {
      mainPackage = pkgs.kdePackages.kdenlive;
      runtimes.program.enable = true;
    };
  };
}
