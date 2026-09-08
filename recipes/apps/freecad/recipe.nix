{
  lib,
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.freecad;
in
{
  apps.freecad = {
    displayName = "FreeCAD";
    description = "General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler.";
    categories = with lib.categories; [ Office ];
    longDescription = ''
      FreeCAD is a free and open-source parametric 3D CAD modeler for mechanical
      design, product design, architecture (BIM), and more. Models are built from
      a history of features that can be edited at any time. The interface is
      organized into workbenches (PartDesign, Sketcher, Part, Draft, BIM, CAM,
      etc.); switch them from the workbench selector.
    '';

    usage = ''
      #### Basic usage (GUI):

      ```bash
      freecad
      ```

      ##### Open a document:

      ```bash
      freecad model.FCStd
      ```

      ##### Headless / CLI:

      ```bash
      freecadcmd
      freecad -c
      freecadcmd script.py
      freecadcmd model.FCStd -o output.step
      ```
    '';

    links = {
      website = "https://www.freecad.org";
      source = "https://github.com/freecad/freecad";
      docs = "https://wiki.freecad.org/Getting_started";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Lens-FreeCAD-integration"
      ];
    };

    programs = {
      mainPackage = pkgs.freecad;
      packages = [ pkgs.freecad ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    data = {
      test = ./test.py;
    };

    test.programs = {
      packages = [
        pkgs.writableTmpDirAsHomeHook
      ];
      script = ''
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
        export QT_QPA_PLATFORM=offscreen
        freecadcmd -c < ${recipe.data.test.path} | grep "Volume: 6000"
      '';
    };
  };
}
