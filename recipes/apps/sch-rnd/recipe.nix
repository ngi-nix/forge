{
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.sch-rnd;
in
{
  apps.sch-rnd = {
    displayName = "sch-rnd";
    description = "Simple, modular, scriptable schematics editor.";
    usage = ''
      sch-rnd is a schematics capture tool for multisheet designs, scriptable
      in over 10 languages, with support for hierarchic design and parametric
      symbol generation. It can be used stand-alone or alongside pcb-rnd as
      part of the RiNgDove EDA suite.

      See the [Docs](${recipe.links.docs}) for more.
    '';

    links = {
      website = "http://www.repo.hu/projects/sch-rnd";
      source = "http://cgi.repo.hu/cgi-bin/minisvn.cgi?cmd=browse&repo=sch-rnd&path=trunk";
      docs = "http://www.repo.hu/projects/sch-rnd/doc.html";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Ringdove-alienformats"
      ];
      Entrust = [
        "Ringdove"
      ];
    };

    programs = {
      mainPackage = pkgs.sch-rnd;
      packages = [ pkgs.sch-rnd ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      sch-rnd --version | grep -q ${pkgs.sch-rnd.version}
    '';

  };
}
