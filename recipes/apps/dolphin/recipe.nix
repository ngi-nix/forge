{
  pkgs,
  config,
  ...
}:

{
  apps.dolphin = {
    displayName = "Dolphin File Manager";
    description = "File Manager by KDE.";
    usage = ''
      Dolphin is KDE's file manager that lets you navigate and browse the contents of your hard drives, USB sticks, SD cards, and more.
      Creating, moving, or deleting files and folders is simple and fast.

      See more information [on Dolphin's homepage](${config.apps.dolphin.links.website}).
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [ "KDE-Dolphin-a11y" ];
      Entrust = [ "DolphinAuth" ];
    };

    links = {
      website = "https://apps.kde.org/dolphin";
      source = "https://invent.kde.org/system/dolphin";
      docs = "https://userbase.kde.org/Special:myLanguage/Dolphin";
    };

    programs = {
      mainPackage = pkgs.kdePackages.dolphin;
      runtimes.program.enable = true;
    };
  };
}
