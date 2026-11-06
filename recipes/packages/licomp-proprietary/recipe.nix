{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-proprietary = {
    version = "0.5.3";
    description = "Implementation of Licomp for linking a Proprietary licensed module.";
    homePage = "https://github.com/hesa/licomp-proprietary";
    license = with lib.licenses; [
      cc-by-40
      gpl3Plus
    ];

    source = {
      git = "github:hesa/licomp-proprietary/0.5.3";
      hash = "sha256-elEy/BOcuvo29ciRRSNQABWoBrOhRPDCNoaypuvWsx0=";
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
        "licomp_proprietary"
      ];
    };
  };
}
