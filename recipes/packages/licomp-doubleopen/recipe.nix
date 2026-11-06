{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-doubleopen = {
    version = "0.1.5";
    description = "Licomp implementation of Double Open Project's license classifications.";
    homePage = "https://github.com/hesa/licomp-doubleopen";
    license = with lib.licenses; [
      cc-by-30
      cc-by-40
      cc0
      gpl3Plus
    ];

    source = {
      git = "github:hesa/licomp-doubleopen/0.1.5";
      hash = "sha256-ju+Ewp5q3bzanLeldtE7NSSlfLpMe6muM4ZlpFgBDh0=";
    };

    build.pythonPackageBuilder = {
      enable = true;

      packages = {
        build-system = with pkgs.python3Packages; [
          setuptools
        ];
        dependencies = with pkgs; [
          licomp
        ];
        check = with pkgs.python3Packages; [
          pytestCheckHook
          jsonschema
        ];
      };

      importsCheck = [
        "licomp_doubleopen"
      ];
    };
  };
}
