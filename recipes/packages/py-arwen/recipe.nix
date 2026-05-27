{
  pkgs,
  packages,
  ...
}:

{
  packages.py-arwen = {
    description = "Python library for cross-platform patching of shared libraries.";

    inherit (packages.arwen)
      source
      version
      homePage
      license
      ;

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
        inherit (pkgs.arwen)
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
  };
}
