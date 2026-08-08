{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-dwheeler = {
    version = "0.5.1";
    description = "Implementation of Licomp using David Wheeler's graph.";
    homePage = "https://github.com/hesa/licomp-dwheeler";
    license = with lib.licenses; [
      cc-by-sa-30
      gpl3Plus
    ];

    source = {
      git = "github:hesa/licomp-dwheeler/0.5.1";
      hash = "sha256-p6BSedKqauJCVpkr18UN6oNLwI2NknfJx8FHBIbi3I4=";
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
        "licomp_dwheeler"
      ];
    };
  };
}
