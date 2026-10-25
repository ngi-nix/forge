{
  forge-lib,
  lib,
  pkgs,
  ...
}:

{
  pkgs.icestudio = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.icestudio;
    };
  };
  apps.icestudio = {
    displayName = "Icestudio";
    description = "Visual developer tool for development of FPGAs.";
    categories = with forge-lib.categories; [ Electronics ];
    screenshotSources.urls = [
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-01-icek-Alhambra-II.png";
        caption = "Alhambra II board";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-02-icek-icebreaker.png";
        caption = "iceBreaker board";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-03-icemem.png";
        caption = "IceMem collection: example 23";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-04-RISC-V.png";
        caption = "RISC-V CPU";
      }
    ];
    usage = ''
      Icestudio is a visual editor for open FPGA boards that lets you design
      digital circuits using a block-based graphical interface.
    '';

    icon = ./icon.svg;

    links = {
      website = "https://icestudio.io/";
      source = "https://github.com/FPGAwars/icestudio";
      docs = "https://github.com/FPGAwars/icestudio/wiki";
    };

    ngi.grants = {
      Entrust = [
        "Icestudio"
      ];
    };

    programs = {
      mainPackage = pkgs.icestudio;
      runtimes.program.enable = true;
    };
  };
}
