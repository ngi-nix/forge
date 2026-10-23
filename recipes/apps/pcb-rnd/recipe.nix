{
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.pcb-rnd;
in
{
  apps.pcb-rnd = {
    displayName = "pcb-rnd";
    description = "Free/open source, flexible, modular Printed Circuit Board editor.";
    usage = ''
      pcb-rnd is an editor for multilayer Printed Circuit Boards, scriptable in
      over 10 languages, with a scriptable Design Rule Checker and parametric
      footprint generation. It is compatible with KiCad and gEDA/PCB, and can
      import Eagle and Protel/Autotrax files. It can be used stand-alone or
      alongside sch-rnd as part of the RiNgDove EDA suite.

      See the [Docs](${recipe.links.docs}) for more.
    '';

    links = {
      website = "http://www.repo.hu/projects/pcb-rnd";
      source = "http://cgi.repo.hu/cgi-bin/minisvn.cgi?cmd=browse&repo=pcb-rnd&path=trunk";
      docs = "http://www.repo.hu/projects/pcb-rnd/doc.html";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Ringdove-alienformats"
      ];
      Entrust = [
        "Ringdove"
      ];
      Review = [
        "pcb-rnd"
      ];
    };

    programs = {
      mainPackage = pkgs.pcb-rnd;
      packages = [ pkgs.pcb-rnd ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      pcb-rnd --version | grep -q ${pkgs.pcb-rnd.version}
    '';

  };
}
