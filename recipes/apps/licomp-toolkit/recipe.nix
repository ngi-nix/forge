{
  forge-lib,
  config,
  pkgs,
  ...
}:

let
  app = config.apps.licomp-toolkit;
  usageSnippets = forge-lib.snippets.usage app;
in

{
  pkgs.licomp-toolkit = {
    unfree = true;
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.licomp-toolkit;
    };
  };

  apps.licomp-toolkit = {
    displayName = "Licomp Toolkit";
    description = "Python module and program to check compatibility between licenses.";
    usage = ''
      First, ${usageSnippets.run-shell}.

      ##### Check license compatibility

      ```bash
      licomp-toolkit GPL-3.0-only MIT
      ```

      ##### List supported licenses

      ```bash
      licomp-toolkit --list
      ```
    '';

    links = {
      source = "https://codeberg.org/software-compliance-org/licomp-toolkit";
      website = "https://software-compliance.org/tooling-resources/licomp-toolkit";
    };

    ngi.grants = {
      Core = [
        "LicenseCompatibilityAutomation"
      ];
    };

    programs = {
      mainPackage = pkgs.licomp-toolkit;
      packages = [ pkgs.licomp-toolkit ];

      runtimes = {
        program.enable = true;
        shell.enable = true;
      };
    };

    test.programs.script = ''
      licomp-toolkit --help
    '';
  };
}
