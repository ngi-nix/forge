{
  pkgs,
  lib,
  ...
}:

{
  apps.zenroom = {
    displayName = "Zenroom";
    description = "No-code cryptographic virtual machine.";
    usage = ''
      Zenroom is a tiny and portable virtual machine that integrates in any application to authenticate and restrict access to data and execute human-readable smart contracts.

      #### Basic Usage

      First, write the following script into a local file (e.g. `arrayGenerator.zen`):

      ```
      ${lib.readFile ./test/arrayGenerator.zen}
      ```

      Then, [enter the Nix shell](app/zenroom#run-shell) and execute the script:

      ```bash
      zenroom -z arrayGenerator.zen | tee myFirstRandomArray.json
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
      packages = with pkgs; [ zenroom ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    test.programs.script = ''
      zenroom -z ${./test/arrayGenerator.zen}
    '';
  };
}
