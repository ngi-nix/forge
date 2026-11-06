{
  lib,
  pkgs,
  ...
}:

{
  packages.spdx-license-list = {
    version = "3.28.0";
    description = "SPDX License List as a Python dictionary.";
    homePage = "https://github.com/JJMC89/spdx-license-list";
    license = lib.licenses.mit;

    source = {
      git = "github:JJMC89/spdx-license-list/v3.28.0";
      hash = "sha256-qzEWa2SY4XfW+DgAl6UNUItYWGJ/dJM6jZ/ZekoVgNc=";
    };

    build.pythonPackageBuilder = {
      enable = true;

      packages = {
        build-system = with pkgs.python3Packages; [
          poetry-core
        ];
      };

      importsCheck = [
        "spdx_license_list"
      ];
    };
  };
}
