{
  packages.ironcalc-python =
    {
      lib,
      pkgs,
      nixpkgs-pkgs,
      packages,
      ...
    }:

    {
      version = "0.7.1-unstable-2026-04-29";
      description = "Python bindings for IronCalc";
      homePage = "https://www.ironcalc.com";
      license = with lib.licenses; [
        asl20
        mit
      ];

      inherit (packages.ironcalc) source;

      build.pythonPackageBuilder = {
        enable = true;
        packages = {
          build = [
            pkgs.pkg-config
            pkgs.rustPlatform.cargoSetupHook
            pkgs.rustPlatform.maturinBuildHook
          ];
          run = [
            pkgs.bzip2
            pkgs.zstd
          ];
          check = [
            pkgs.python3Packages.pytestCheckHook
          ];
        };
        importsCheck = [ "ironcalc" ];
      };

      build.extraAttrs = {
        postPatch = ''
          cd bindings/python
        '';

        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (pkgs.ironcalc) src;
          hash = pkgs.ironcalc-tools.cargoHash;
        };

        cargoRoot = "../..";
      };
    };
}
