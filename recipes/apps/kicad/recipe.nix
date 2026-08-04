{
  pkgs,
  ...
}:
{
  apps.kicad = {
    displayName = "KiCAD";
    description = "KiCAD is a free software suite for electronic design automation (EDA).";
    usage = ''
      KiCAD is a free software suite for electronic design automation (EDA). It facilitates the design of schematics for electronic circuits and their conversion to PCB designs.

      Get started [here](https://docs.kicad.org/10.0/en/getting_started_in_kicad/getting_started_in_kicad.html).
    '';

    links = {
      website = "https://kicad.org";
      docs = "https://docs.kicad.org";
      source = "https://gitlab.com/kicad/code/kicad";
    };

    ngi.grants = {
      Commons = [
        "KiCad-10"
      ];
      Core = [
        "KiCad-IPC"
      ];
      Review = [
        "KiCad"
      ];
    };

    icon = ./icon.svg;

    programs = {
      mainPackage = pkgs.kicad;
      packages = [ pkgs.kicad ];
      runtimes.shell.enable = true;
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      kicad-cli --version | grep -q "${pkgs.kicad.version}"
    '';
  };
}
