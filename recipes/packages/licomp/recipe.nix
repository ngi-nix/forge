{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp = {
    version = "0.5.22";
    description = "License Compatibility - Generalised API for use in license compatibility.";
    homePage = "https://codeberg.org/software-compliance-org/licomp";
    license = with lib.licenses; [ gpl3Plus ];

    source = {
      git = "codeberg:software-compliance-org/licomp/0.5.22";
      hash = "sha256-yZZfWinXdMmF/FQQ3+MwHRypK5Xz2EEMruJLCAtl/6Q=";
    };

    build.pythonPackageBuilder = {
      enable = true;

      packages = {
        build-system = with pkgs.python3Packages; [
          setuptools
        ];
        dependencies = with pkgs.python3Packages; [
          pyyaml
        ];
        check = with pkgs.python3Packages; [
          pytestCheckHook
          jsonschema
        ];
      };

      importsCheck = [
        "licomp"
      ];
    };
  };
}
