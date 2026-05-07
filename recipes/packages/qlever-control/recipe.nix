{
  config,
  pkgs,
  lib,
  ...

}:

{
  name = "qlever-control";
  version = "0.5.46";
  description = "Command-line tool for controlling the QLever graph database";
  license = lib.licenses.asl20;

  homePage = "https://github.com/qlever-dev/qlever-control";
  mainProgram = "qlever";

  source = {
    git = "github:qlever-dev/qlever-control/v0.5.46";
    hash = "sha256-vXSVrNfz4gRBCrTi0D+sXtfsAZwv7HO67zs7wh98cOY=";
  };

  build.pythonAppBuilder = {
    enable = true;
    packages = {
      build-system = with pkgs.python3Packages; [
        setuptools
        wheel
      ];
      dependencies = with pkgs.python3Packages; [
        argcomplete
        psutil
        pyyaml
        rdflib
        termcolor
        tqdm
        pkgs.mypkgs.requests-sse
      ];
    };
    importsCheck = [
      "qlever"
    ];
  };

  test.script = ''
    qlever --help 2>&1 /dev/null | grep "usage: qlever"
  '';
}
