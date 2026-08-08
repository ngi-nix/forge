{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-gnuguide = {
    version = "0.5.2";
    description = "Implementation of Licomp using GNU resources.";
    homePage = "https://github.com/hesa/licomp-gnuguide";
    license = with lib.licenses; [
      cc-by-nd-40
      gpl3Plus
    ];

    source = {
      git = "github:hesa/licomp-gnuguide/0.5.2";
      hash = "sha256-DfjrmEktlTFvKqHIlmM/XeWZ4s24cRtWqs65OLDYZNQ=";
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
        "licomp_gnuguide"
      ];
    };
  };
}
