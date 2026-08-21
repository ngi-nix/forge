{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-osadl = {
    version = "0.5.1";
    description = "Implementation of Licomp using OSADL's matrix.";
    homePage = "https://github.com/hesa/licomp-osadl";
    license = with lib.licenses; [
      cc-by-40
      gpl3Plus
    ];

    source = {
      git = "github:hesa/licomp-osadl/0.5.1";
      hash = "sha256-aWJG7HxYs/8/Km3EpY8/XewCILlgePoKsdJyL8CM6LI=";
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
        "licomp_osadl"
      ];
    };
  };
}
