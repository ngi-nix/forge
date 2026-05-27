{
  pkgs,
  ...
}:

{
  apps.bang = {
    displayName = "BANG";
    description = "Binary Analysis Next Generation framework for recursive unpacking and analysis of binary files.";
    usage = ''
      BANG recursively unpacks and classifies binary files, supporting 220+ formats
      including firmware images, archives, file systems, and executables.

      #### Scan a binary file

      ```bash
      bang scan -u /tmp/bang-results /path/to/firmware.bin
      ```

    '';

    links = {
      source = "https://github.com/armijnhemel/binaryanalysis-ng";
    };

    ngi.grants = {
      Review = [
        "BANG"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.bang
      ];
      runtimes.shell = {
        enable = true;
      };
    };
  };
}
