{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-oslc-handbook = {
    version = "0.1.2";
    description = "Licomp implementation of OSLC-handbook.";
    homePage = "https://github.com/hesa/licomp-oslc-handbook";
    license = with lib.licenses; [
      cc-by-40
      cc-by-sa-40
      gpl3Plus
    ];

    source = {
      git = "github:hesa/licomp-oslc-handbook/0.1.2";
      hash = "sha256-cgvwFwKlClEPfj9DWvxdBFpnYpdhdXBPsM+qPXxb+SE=";
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
        "licomp_oslc_handbook"
      ];
    };
  };
}
