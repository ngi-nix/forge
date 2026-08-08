{
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.labplot;
in
{
  apps.labplot = {
    displayName = "LabPlot";
    description = "Free, open-source, cross-platform data visualization and analysis software.";
    usage = ''
      LabPlot is a data visualization and analysis application, offering
      plotting, statistics, interactive notebooks, and data extraction from
      plots, with support for live data and a wide range of import/export
      formats.
      For more information, see [the LabPlot website](${recipe.links.website}).
    '';

    links = {
      website = "https://labplot.org";
      docs = "https://docs.labplot.org";
      source = "https://invent.kde.org/education/labplot";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "LabPlot-domain-specific"
      ];
      Core = [
        "LabPlot"
      ];
    };

    programs = {
      mainPackage = pkgs.labplot;
      packages = [ pkgs.labplot ];
      runtimes.shell.enable = true;
      runtimes.program.enable = true;
    };

    test.programs = {
      packages = [ pkgs.xvfb-run ];
      script = ''
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
        export QT_QPA_PLATFORM=offscreen
        xvfb-run labplot --help-all | grep -q "LabPlot"
      '';
    };
  };
}
