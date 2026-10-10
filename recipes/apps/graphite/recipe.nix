{
  pkgs,
  ...
}:
{
  pkgs.graphite = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.graphite;
    };
  };
  apps.graphite = {
    displayName = "Graphite";
    description = "Free, open source vector graphics editor and animation engine.";
    usage = ''
      Graphite is a vector and raster graphics editor with a fully
      nondestructive editing workflow, combining layer-based compositing with
      node-based generative design.
    '';

    links = {
      website = "https://graphite.art";
      source = "https://github.com/GraphiteEditor/Graphite";
      docs = "https://graphite.art/learn";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Graphite"
      ];
    };

    programs = {
      mainPackage = pkgs.graphite;
      packages = [ pkgs.graphite ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      # graphite is in alpha stage, so no version number yet.
      graphite --version | grep -q "graphite"
    '';
  };
}
