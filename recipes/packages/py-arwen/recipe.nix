{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "py-arwen";
  version = "0.0.5-unstable-2026-04-07";
  description = "Python library for cross-platform patching of shared libraries.";
  homePage = "https://github.com/nichmor/arwen";
  license = lib.licenses.mit;

  source = {
    git = "github:nichmor/arwen/696351a8c208315b0dfd4a1e5c37288a689ccd2e";
    hash = "sha256-6RW8BeKjoxeO8SBz/VdZGnrRW+EIKq5NtrFdM0lx0+o=";
  };

  build.pythonPackageBuilder = {
    enable = true;
    packages = {
      build = with pkgs; [
        python3Packages.setuptools
        rustPlatform.cargoSetupHook
        rustPlatform.maturinBuildHook
      ];
      check = with pkgs; [
        python3Packages.pytestCheckHook
      ];
    };
    importsCheck = [
      "arwen"
    ];
  };

  build.extraAttrs = {
    sourceRoot = "source/py-arwen";

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit (pkgs.mypkgs.arwen)
        pname
        version
        src
        ;
      sourceRoot = "source/py-arwen";
      hash = "sha256-SJ3RZ/kCfMJb26uaJEQzA2NXOCudyqbJpbvC4d/R/T8=";
    };

    preCheck = ''
      # conflicts with built module
      rm -r arwen
    '';
  };
}
