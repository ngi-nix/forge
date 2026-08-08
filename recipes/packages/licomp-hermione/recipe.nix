{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-hermione = {
    version = "0.5.2";
    description = "Implementation of Licomp using the Hermine license resource.";
    homePage = "https://github.com/hesa/licomp-hermione";
    license = with lib.licenses; [
      bsd0
      gpl3Plus
      odbl
    ];

    source = {
      git = "github:hesa/licomp-hermione/0.5.2";
      hash = "sha256-TIfi7E+BBChOz/EXRJxjFRYavVRPfnSkBHTaiY87k/Y=";
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
        "licomp_hermione"
      ];
    };
  };
}
