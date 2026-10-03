{
  lib,
  pkgs,
  ...
}:

{
  packages.licomp-toolkit = {
    version = "0.5.20";
    description = "Python module and program to check compatibility between two licenses with context.";
    homePage = "https://codeberg.org/software-compliance-org/licomp-toolkit";
    mainProgram = "licomp-toolkit";
    license = with lib.licenses; [ gpl3Plus ];

    source.git = "codeberg:software-compliance-org/licomp-toolkit/0.5.20";
    source.hash = "sha256-E6ehhQj1EcpW+8Cf2b+dtYSCH7fQ/AgS8uWIN4ipeCQ=";

    build.pythonPackageBuilder = {
      enable = true;

      packages = {
        build-system = with pkgs.python3Packages; [
          setuptools
        ];
        dependencies = with pkgs; [
          foss-flame
          licomp
          licomp-doubleopen
          licomp-dwheeler
          licomp-gnuguide
          licomp-hermione
          licomp-osadl
          licomp-oslc-handbook
          licomp-proprietary
          licomp-reclicense
          pkgs.python3Packages.pyyaml
        ];
        check = with pkgs.python3Packages; [
          pytestCheckHook
        ];
      };

      importsCheck = [
        "licomp_toolkit"
      ];
    };
  };
}
