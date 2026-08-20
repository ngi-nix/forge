{
  forge-lib,
  pkgs,
  config,
  ...
}:
let
  app = config.apps.graphite;
  usageSnippets = forge-lib.snippets.usage app;
in
{
  pkgs.graphite = {
    unfree = true;
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.graphite;
    };
  };

  apps.graphite = {
    displayName = "Graphite";
    description = "Free, open source vector graphics editor and animation engine.";
    longDescription = ''
      Graphite is a vector and raster graphics editor with a fully
      nondestructive editing workflow, combining layer-based compositing with
      node-based generative design.
    '';
    usage = ''
      First, ${usageSnippets.run-program} or ${usageSnippets.run-shell}.
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

    # graphite is in alpha stage, so no version number yet.
    test.programs.script = ''
      graphite --version | grep -q "graphite"
    '';
  };
}
