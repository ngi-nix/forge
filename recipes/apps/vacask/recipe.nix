{
  config,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.vacask;
in

{
  apps.vacask = {
    displayName = "VACASK";
    description = "Analog circuit simulator.";

    data = {
      testOp = ./tests/test_op.sim;
      testCommit = "bf59752fbfdfed18dc7fe2e3e11a9c02f8de28a0";
    };

    usage = ''
      VACASK (Verilog-A Circuit Analysis Kernel) is an analog circuit
      simulator with a device library built from Verilog-A modules.

      #### Basic Usage

      For testing, download one of the [upstream test files](https://codeberg.org/arpadbuermen/VACASK/src/commit/${app.data.testCommit}/test). For example:

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
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      vacask --help | grep -q "This is vacask ${pkgs.vacask.version}"
      vacask ${app.data.testOp.path}
    '';
  };

  pkgs.vacask = {
    build.identityBuilder = {
      enable = true;
      # TODO: remove when this is merged and propagated
      # https://github.com/NixOS/nixpkgs/pull/554242
      derivation = pkgs.pkgsOriginal.vacask.overrideAttrs (oldAttrs: {
        cmakeFlags = oldAttrs.cmakeFlags ++ [
          (lib.cmakeFeature "OPENVAF_OPTIONS" "--target_cpu ${
            with pkgs.stdenv.hostPlatform;
            if isx86_64 then
              if avx512Support then
                "x86-64-v4"
              else if avx2Support then
                "x86-64-v3"
              else if sse4_2Support then
                "x86-64-v2"
              else
                "x86-64"
            else
              "generic"
          } ")
        ];
      });
    };
  };
}
