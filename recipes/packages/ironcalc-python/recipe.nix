{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ironcalc-python";
  version = "0.7.1-unstable-2026-04-29";
  description = "Python bindings for IronCalc.";
  homePage = "https://www.ironcalc.com";
  license = with lib.licenses; [
    asl20
    mit
  ];

  source = {
    git = "github:ironcalc/ironcalc/8461ff71347ab19145cd7ad50ef829181ba765c2";
    hash = "sha256-vjI3M+hS9bXK8QQlopAy6f4dCISfQHGMvN9sMNKp88Q=";
  };

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
      inherit (pkgs.mypkgs.ironcalc) src;
      hash = pkgs.mypkgs.ironcalc-tools.cargoHash;
    };

    cargoRoot = "../..";
  };
}
