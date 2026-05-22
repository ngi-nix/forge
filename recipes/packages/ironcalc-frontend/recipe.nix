{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ironcalc-frontend";
  version = "0.7.1-unstable-2026-04-29";
  description = "Ironcalc frontend package.";
  homePage = "https://www.ironcalc.com";
  license = with lib.licenses; [
    mit
    asl20
  ];

  source = {
    git = "github:ironcalc/ironcalc/8461ff71347ab19145cd7ad50ef829181ba765c2";
    hash = "sha256-vjI3M+hS9bXK8QQlopAy6f4dCISfQHGMvN9sMNKp88Q=";
  };

  build.npmPackageBuilder = {
    enable = true;
    npmDepsHash = "sha256-QVpUV3dxaqiWCF8RC1MR2ylYC500Lbp5pJgzzOrF20c=";
    packages.build = [
      pkgs.mypkgs.ironcalc-wasm
      pkgs.mypkgs.ironcalc-widget
    ];
  };

  build.extraAttrs = {
    sourceRoot = "source/webapp/app.ironcalc.com/frontend";

    postPatch = ''
      chmod -R u+w ../../..

      # wasm location fix
      mkdir -p ../../../bindings/wasm/pkg
      cp -rv ${pkgs.mypkgs.ironcalc-wasm}/. ../../../bindings/wasm/pkg/

      rm -rf ../../IronCalc
      cp -r ${pkgs.mypkgs.ironcalc-widget} ../../IronCalc
      chmod -R u+w ../../IronCalc
    '';

    preBuild = ''
      # wasm resolution fix
      rm -rf node_modules/@ironcalc/wasm
      mkdir -p node_modules/@ironcalc
      cp -rv ${pkgs.mypkgs.ironcalc-wasm}/. node_modules/@ironcalc/wasm

      # workbook resolution fix
      rm -rf node_modules/@ironcalc/workbook
      mkdir -p node_modules/@ironcalc
      cp -rv ${pkgs.mypkgs.ironcalc-widget}/. node_modules/@ironcalc/workbook
    '';

    installPhase = ''
      mkdir -p $out
      cp -r dist/. $out
    '';
  };
}
