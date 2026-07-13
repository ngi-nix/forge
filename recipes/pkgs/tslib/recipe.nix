{
  lib,
  pkgs,
  config,
  ...
}:

{
  pkgs.tslib = {
    version = "1.24";
    description = "Touchscreen access library.";
    homePage = "http://www.tslib.org/";
    mainProgram = "";
    license = lib.licenses.lgpl21;

    source = {
      git = "github:libts/tslib/1.24-rc1";
      hash = "sha256-mTei2djePes+H9MfKRoL7AujCYh6D0UHWLtDuemwI/0=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = [
        pkgs.cmake
      ];
    };
  };
}
