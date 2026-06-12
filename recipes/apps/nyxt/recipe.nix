{
  pkgs,
  ...
}:

{
  apps.nyxt = {
    displayName = "Nyxt";
    description = "Infinitely extensible web browser with Lisp-based customization.";
    usage = ''
      Nyxt is a keyboard-driven web browser designed to be customized and extended
      using Common Lisp. It emphasizes privacy, efficiency, and user control.
    '';

    icon = ./icon.svg;

    links = {
      website = "https://nyxt.atlas.engineer";
      docs = "https://nyxt.atlas.engineer/documentation";
      source = "https://github.com/atlas-engineer/nyxt";
    };

    ngi.grants = {
      Entrust = [
        "Nyxt-Webextensions"
      ];
      Review = [
        "NyxtBrowser"
        "NyxtUserhosted"
      ];
    };

    programs = {
      mainPackage = pkgs.nyxt;
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      nyxt --version 2>&1 | grep -qE "[0-9]+\.[0-9]+"
    '';
  };
}
