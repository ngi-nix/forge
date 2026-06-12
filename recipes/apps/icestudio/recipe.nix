{
  pkgs,
  ...
}:

{
  apps.icestudio = {
    displayName = "Icestudio";
    description = "Visual developer tool for development of FPGAs.";
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
