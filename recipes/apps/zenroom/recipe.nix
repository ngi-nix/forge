{
  config,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.zenroom;
in

{
  pkgs.zenroom = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.zenroom;
    };
  };
  apps.zenroom = {
    displayName = "Zenroom";
    description = "No-code cryptographic virtual machine.";

    data = {
      arrayGenerator = ./test/arrayGenerator.zen;
    };

    usage = ''
      Zenroom is a tiny and portable virtual machine that integrates in any application to authenticate and restrict access to data and execute human-readable smart contracts.

      #### Basic Usage

      First, write the following script into a local file (e.g. `${app.data.arrayGenerator.name}`):

      ```
      ${app.data.arrayGenerator}
      ```

      Then, [enter the Nix shell](app/zenroom#run-shell) and execute the script:

      ```bash
      zenroom -z ${app.data.arrayGenerator.name} | tee myFirstRandomArray.json
      ```

      The result should be printed in the terminal and also in the `myFirstRandomArray.json` file.

      For explanations on the Zencode script syntax and more advanced examples, please refer to the [project documentation](https://dev.zenroom.org).
    '';

    links = {
      website = "https://zenroom.org";
      source = "https://github.com/dyne/Zenroom";
      docs = "https://dev.zenroom.org";
    };

    ngi.grants = {
      Review = [
        "Zenroom-oqs"
      ];
    };

    programs = {
      mainPackage = pkgs.zenroom;
      packages = [ pkgs.zenroom ];

      runtimes.shell.enable = true;
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      zenroom -z ${app.data.arrayGenerator.path}
    '';
  };
}
