{
  lib,
  config,
  pkgs,
  ...
}:

{
  pkgs.python3-padne.build.identityBuilder = {
    enable = true;
    derivation = pkgs.pkgsOriginal.python3Packages.padne;
  };
  pkgs.padne.build.identityBuilder = {
    enable = true;
    derivation = pkgs.pkgsOriginal.padne;
  };

  apps.padne = {
    displayName = "Padne";
    description = "KiCad-focused Power Delivery Network Simulator.";
    categories = with lib.categories; [ Network ];
    usage = ''
      Padne is a KiCad-native power delivery network analysis tool.

      It uses the finite element method in order to simulate the voltage drop
      induced by DC currents on printed circuit boards.

      This allows easy identification of resistive bottlenecks, design of high
      current distribution networks or implementing complex heating elements.

      #### Basic Usage

      Inside a KiCad project, padne is configured through a `!padne` directive, followed by the directive name and its parameters [^1].

      For testing, you can download one of the [upstream KiCad test-projects](https://github.com/atx/padne/tree/ab96a25fea84d4938bcd2c81964650351549c2f8/tests/kicad). For example:

      ```bash
      for extension in kicad_pcb kicad_pro kicad_sch; do
        wget https://raw.githubusercontent.com/atx/padne/ab96a25fea84d4938bcd2c81964650351549c2f8/tests/kicad/via_tht_4layer/via_tht_4layer."$extension"
      done
      ```

      After you have a KiCad project with padne directives, you can run the solver and display the solution in one step:

      ```bash
      padne gui via_tht_4layer.kicad_pro
      ```

      Or, you can save the solution and display it at a later time:

      ```bash
      padne solve via_tht_4layer.kicad_pro pdn.padne
      padne show pdn.padne
      ```

      For more details and advanced usage, please refer to the [project documentation](${config.apps.padne.links.docs}).

      [^1]: https://padne.atx.name/master/user_guide/directives.html
    '';

    links = {
      website = "https://padne.atx.name/master/index.html";
      source = "https://github.com/atx/padne";
      docs = "https://padne.atx.name/master/index.html";
    };

    ngi.grants = {
      Commons = [
        "Padne"
      ];
    };

    programs = {
      mainPackage = pkgs.padne;
      packages = with pkgs; [
        padne
        (python3.withPackages (ps: [
          pkgs.python3-padne
        ]))
      ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    test.programs =
      let
        testSource = pkgs.fetchFromGitHub {
          owner = "atx";
          repo = "padne";
          rev = "ab96a25fea84d4938bcd2c81964650351549c2f8";
          sparseCheckout = [ "tests" ];
          hash = "sha256-SslrwyzAysZuB1DhV48gbVcc01G+TJyvUcIda7A05mk=";
        };
      in
      {
        packages = with pkgs; [
          writableTmpDirAsHomeHook
        ];
        script = ''
          padne solve \
            ${testSource}/tests/kicad/via_tht_4layer/via_tht_4layer.kicad_pro \
            pdn.padne
        '';
      };
  };
}
