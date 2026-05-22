{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ironcalc-widget";
  version = "0.7.1-unstable-2026-04-29";
  description = "Ironcalc frontend widget package.";
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
    npmDepsHash = "sha256-jPnUUEOjW9WHVjpBH/qKB4P5RuMI0uvjog8C41cPQdY=";
    packages.build = [
      pkgs.mypkgs.ironcalc-wasm
    ];
  };

  build.extraAttrs = {
    sourceRoot = "source/webapp/IronCalc";

    postPatch = ''
      chmod -R u+w ../../bindings

      # We are now in source/webapp/IronCalc
      mkdir -p ../../bindings/wasm/pkg
      echo '{"name": "@ironcalc/wasm", "version": "${config.version}"}' > ../../bindings/wasm/pkg/package.json
    '';

    preConfigure = ''
      cp -rv ${pkgs.mypkgs.ironcalc-wasm}/. ../../bindings/wasm/pkg/
    '';

    # copy instead of symlinking to avoid noBrokenSymlinks check failing in fixupPhase.
    preBuild = ''
      rm -rf node_modules/@ironcalc/wasm
      mkdir -p node_modules/@ironcalc
      cp -rv ${pkgs.mypkgs.ironcalc-wasm}/. node_modules/@ironcalc/wasm
    '';

    buildPhase = ''
      npm run build
    '';

    installPhase = ''
      mkdir -p $out
      cp -r . $out
    '';
  };
}
