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
        caption = "Hello world example for the Alhambra II board";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-02-icek-icebreaker.png";
        caption = "Hello world example for the iceBreaker board";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-03-icemem.png";
        caption = "Example from the IceMem collection";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-03-1-spi-display-7seg.png";
        caption = "SPI controller for a 4-digit 7-segment display";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-04-RISC-V.png";
        caption = "RISC-V CPU";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-05-Z80.png";
        caption = "Z80 CPU";
      }
      {
        url = "https://raw.githubusercontent.com/FPGAwars/icestudio-wiki/main/Readme/screenshot-06-Hack-Nand2tetris.png";
        caption = "Hack CPU from the Nand2tetris project";
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
