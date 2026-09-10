{
  config,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.emerge;
  pyEnv = pkgs.python3.withPackages (ps: [ pkgs.python3-emerge ]);
in

{
  pkgs.python3-emerge.build.identityBuilder = {
    enable = true;
    derivation = pkgs.python3Packages.emerge;
  };
  pkgs.emerge.build.identityBuilder = {
    enable = true;
    derivation = pkgs.python3Packages.toPythonApplication pkgs.python3-emerge;
  };

  apps.emerge = {
    displayName = "EMerge";
    description = "Electromagnetic field computation program.";
    longDescription = ''
      EMerge is a python based FEM EM library for the time harmonic helmholtz formulation.

      You can use it to simulate:

      - RF Filters
      - Signal propagation through PCBs
      - Antennas
      - Optycal systems
      - Arrays and periodic structures
      - Much more!
    '';
    usage = ''
      Write the following script into a local file:

      ```python file ${app.data.first-sim.name}
      ${app.data.first-sim.value}
      ```

      Then, [enter the Nix shell](app/emerge#run-shell) and execute the script:

      ```bash
      python ${app.data.first-sim.name}
      ```

      Screenshots of the result will be written in the same directory as the script.

      For more details and examples, please see the latest user manual in the [project documentation](${config.apps.emerge.links.docs}) page.
    '';

    data = {
      first-sim = ./tests/first-simulation.py;
    };

    links = {
      website = "https://www.emerge-software.com";
      source = "https://github.com/FennisRobert/EMerge";
      docs = "https://www.emerge-software.com/resources";
    };

    ngi.grants = {
      Commons = [
        "EMerge"
      ];
    };

    programs = {
      mainPackage = pkgs.emerge;
      packages = with pkgs; [
        emerge
        pyEnv
      ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    test.programs = {
      packages = with pkgs; [
        mesa.llvmpipeHook # OpenGL context
        pyEnv
        writableTmpDirAsHomeHook
        xvfb-run
      ];
      script = ''
        export NUMBA_DISABLE_JIT=1 # quite slow and won't be cached anyways
        xvfb-run python ${./tests/first-simulation.py}
      '';
    };
  };
}
