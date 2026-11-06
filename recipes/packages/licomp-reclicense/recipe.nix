{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-reclicense = {
    version = "0.5.1";
    description = "Implementation of Licomp using the Reclicense matrix.";
    homePage = "https://github.com/hesa/licomp-reclicense";
    license = with lib.licenses; [
      gpl3Plus
      mulan-psl2
    ];

    source = {
      git = "github:hesa/licomp-reclicense/0.5.1";
      hash = "sha256-dCUsSZ70iKNCk8QcTtQ6Kn8BdyqK2E3Arkfx4aHmhmM=";
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
        "licomp_reclicense"
      ];
    };
  };
}
