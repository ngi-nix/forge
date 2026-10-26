{
  config,
  pkgs,
  ...
}:

let
  app = config.apps.torch-lens-maker;
in

{
  pkgs.torch-lens-maker = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.python3Packages.torchlensmaker;
    };
  };

  apps.torch-lens-maker = {
    displayName = "Torch Lens Maker";
    description = "Python library for modeling and designing optical systems.";
    usage = ''
      First, [launch the shell environment](app/${app.name}#run-shell) containing the `${app.name}` library.

      Second, start Jupyter Notebook, which is currently the preferred way to use the software:

      ```bash
      jupyter notebook
      ```

      Next, in the top left, click on `File > New > Notebook` and select `Python 3 (ipykernel)`.
      Once that's open, copy the following code block in the empty cell:

      ```python
      import torchlensmaker as tlm

      optics = tlm.Sequential(
          tlm.ObjectAtInfinity(beam_diameter=10, angular_size=20),
          tlm.Gap(15),
          tlm.RefractiveSurface(
              tlm.SphereByCurvature(diameter=25, C=1 / -45.0), materials=("air", "BK7")
          ),
          tlm.Gap(3),
          tlm.RefractiveSurface(
              tlm.SphereByCurvature(diameter=25, C=tlm.parameter(1 / -20)),
              materials=("BK7", "air"),
          ),
          tlm.Gap(100),
          tlm.ImagePlane(50),
      )

      tlm.show2d(optics, title="Landscape Lens")
      ```

      Then, either run it by clicking the arrow key in the tool bar or by typing `Shift+Enter` on the keyboard.
      If everything worked correctly, the lens image will be displayed under the code cell.

      For more details and examples, please see the [project documentation](${app.links.docs}) page.
    '';

    links = {
      website = "https://victorpoughon.github.io/torchlensmaker";
      source = "https://github.com/victorpoughon/torchlensmaker";
      docs = "https://victorpoughon.github.io/torchlensmaker/doc/getting-started";
    };

    ngi.grants = {
      Commons = [
        "Torch-LensMaker"
      ];
    };

    programs = {
      packages = with pkgs; [ torch-lens-maker.pyEnv ];

      runtimes = {
        shell.enable = true;
        browser.enable = true;
      };
    };
  };
}
