{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Ironcalc frontend package";

  inherit (rootConfig.forge.packages.ironcalc)
    homePage
    license
    source
    version
    ;

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
