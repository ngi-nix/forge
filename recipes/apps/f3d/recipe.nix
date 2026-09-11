{
  lib,
  pkgs,
  config,
  ...
}:
{
  pkgs.f3d = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.f3d;
    };
  };
  apps.f3d = {
    displayName = "F3D";
    description = "Fast and minimalist 3D viewer.";
    categories = with lib.categories; [ Development ];
    usage = ''
      F3D is a fast and minimalist 3D viewer desktop application.
      It supports many file formats, from digital content to scientific datasets (including glTF, USD, STL, STEP, PLY, OBJ, FBX, Alembic),
      can show animations and support thumbnails and many rendering and texturing options including real time physically based rendering and raytracing.

      #### Getting Started

      Open a file directly in F3D or from the command line by running:

      ```bash
      f3d /path/to/file.ext
      ```
      Optionally, you can also save the rendering into an image file:

      ```bash
      f3d /path/to/file.ext --output=/path/to/img.png
      ```

      If you need help, specify the --help option:

      ```bash
      f3d --help
      man f3d # Linux only
      ```
      Once you've opened your file in F3D, you're all set to start visualizing! Press `H` to open a list of shortcuts to help you interact with your scene.
    '';

    links = {
      website = "https://f3d.app";
      source = "https://github.com/f3d-app/f3d";
      docs = "https://f3d.app/docs/user/QUICKSTART";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "F3D"
        "F3D-animations"
      ];
    };

    programs = {
      mainPackage = pkgs.f3d;
      packages = [ pkgs.f3d ];
      runtimes.shell.enable = true;
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      f3d --version | grep -q "${config.pkgs.f3d.version}"
    '';
  };
}
