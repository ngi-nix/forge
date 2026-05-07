{
  systemConfig,
  config,
  pkgs,
  lib,
  ...
}:

{
  displayName = "Kepler Formal";
  description = "Formal verification tool for Verilog and Naja interchange format.";
  usage = ''
    Kepler Formal is a CLI tool for formal verification of logic equivalence between two netlists.

    #### Example

    Download example Verilog files

    ```
    mkdir example-data && cd example-data

    for file in \
      tinyrocket.v \
      tinyrocket_edited.v \
      NangateOpenCellLibrary_typical.lib \
      fakeram45_1024x32.lib \
      fakeram45_64x32.lib \
      fakeram45_64x15.lib
    do wget https://raw.githubusercontent.com/keplertech/kepler-formal/refs/heads/main/example/$file
    done
    ```

    Run program

    ```
    kepler-formal -verilog \
      tinyrocket.v \
      tinyrocket_edited.v \
      NangateOpenCellLibrary_typical.lib \
      fakeram45_1024x32.lib \
      fakeram45_64x32.lib \
      fakeram45_64x15.lib
    ```

    _Available in: shell._
  '';

  links = {
    source = "https://github.com/keplertech/kepler-formal";
  };

  ngi.grants = {
    Commons = [
      "Naja-LEC-TimingModelEngine"
    ];
  };

  programs = {
    packages = [
      systemConfig.packages.kepler-formal
    ];

    runtimes.shell = {
      enable = true;
    };
  };
}
