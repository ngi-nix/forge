{
  config,
  forgeConfig,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.vacask;
  usageSnippets = forgeConfig.forge.snippets.usage app;
in

{
  pkgs.vacask = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.vacask;
    };
  };

  apps.vacask = {
    displayName = "VACASK";
    description = "Analog circuit simulator.";
    longDescription = ''
      VACASK (Verilog-A Circuit Analysis Kernel) is an analog circuit
      simulator with a device library built from Verilog-A modules.
    '';

    data = {
      testOp = ./tests/test_op.sim;
      testCommit = "bf59752fbfdfed18dc7fe2e3e11a9c02f8de28a0";
    };

    usage = ''
      First, ${usageSnippets.run-shell}.

      Then, download one of the [upstream test files](https://codeberg.org/arpadbuermen/VACASK/src/commit/${app.data.testCommit}/test) for testing.
      For example:

      ```bash
      wget https://codeberg.org/arpadbuermen/VACASK/raw/commit/${app.data.testCommit}/test/${app.data.testOp.name}
      ```

      Afterwards, run the simulation on the netlist file you downloaded:

      ```bash
      vacask ${app.data.testOp.name}
      ```

      For more details and advanced usage, please refer to the [VACASK User's Manual](${app.links.docs}).
    '';

    links = {
      website = "https://codeberg.org/arpadbuermen/VACASK";
      source = "https://codeberg.org/arpadbuermen/VACASK";
      docs = "https://codeberg.org/arpadbuermen/VACASK/src/branch/main/docs/index.md";
    };

    ngi.grants = {
      Commons = [
        "VACASK"
      ];
    };

    programs = {
      mainPackage = pkgs.vacask;
      packages = with pkgs; [
        vacask
        # some upstream examples require these
        (python3.withPackages (
          ps: with ps; [
            matplotlib
            numpy
            scipy
          ]
        ))
      ];
      runtimes.shell.enable = true;
      runtimes.browser.enable = true;
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      vacask --help | grep -q "This is vacask ${pkgs.vacask.version}"
      vacask ${app.data.testOp.path}
    '';
  };
}
