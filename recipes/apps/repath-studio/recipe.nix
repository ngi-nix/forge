{
  pkgs,
  ...
}:

{
  apps.repath-studio = {
    displayName = "Repath Studio";
    description = "SVG editor written in Clojurescript.";
    usage = ''
      Repath Studio is a cross platform vector graphics editor, that combines procedural tooling with traditional design workflows.

      It includes an interactive shell, which allows evaluating code to generate shapes, or even extend the editor on the fly.
    '';

    icon = ./icon.svg;

    links = {
      website = "https://repath.studio";
      source = "https://github.com/repath-studio/repath-studio";
      docs = "https://repath.studio/get-started/interactive-shell";
    };

    ngi.grants = {
      Commons = [ "RepathStudio" ];
    };

    programs = {
      mainPackage = pkgs.repath-studio;
      runtimes.program.enable = true;
    };
  };
}
