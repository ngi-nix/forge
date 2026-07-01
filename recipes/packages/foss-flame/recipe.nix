{
  lib,
  pkgs,
  ...
}:

{
  packages.foss-flame = {
    version = "0.21.8";
    description = "License meta data: data and python module/cli.";
    homePage = "https://github.com/hesa/foss-licenses";
    mainProgram = "flame";
    license = with lib.licenses; [
      bsd2
      cc-by-40
      gpl3Plus
    ];

    source = {
      git = "github:hesa/foss-licenses/0.21.8";
      hash = "sha256-EEpw1OJKMAlYu8EFxu+/AWFMIMO25TCx2jdT1rxNhOo=";
    };

    build.pythonPackageBuilder = {
      enable = true;

      packages = {
        build-system = with pkgs.python3Packages; [
          setuptools
        ];
        dependencies = with pkgs.python3Packages; [
          jsonschema
          license-expression
          pkgs.osadl-matrix
          pkgs.spdx-license-list
          pyyaml
        ];
        check = with pkgs.python3Packages; [
          pytestCheckHook
        ];
      };
    };

    build.extraAttrs = {
      sourceRoot = "source/python";

      # Upstream setup.cfg has addopts, requiring pytest-{cov,forked,random-order}.
      # Clearing it is simpler than replicating those plugins, especially since
      # they only affect how tests run.
      pytestFlags = [
        "--override-ini=addopts="
      ];

      preCheck = ''
        ln -s ../tests .
      '';
    };
  };
}
