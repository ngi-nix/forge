{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ironcalc-nodejs";
  description = "Node.js bindings for IronCalc.";
  homePage = "https://www.ironcalc.com";
  version = "0.7.1-unstable-2026-04-29";
  license = with lib.licenses; [
    asl20
    mit
  ];

  source = {
    git = "github:ironcalc/ironcalc/8461ff71347ab19145cd7ad50ef829181ba765c2";
    hash = "sha256-vjI3M+hS9bXK8QQlopAy6f4dCISfQHGMvN9sMNKp88Q=";
  };

  build.pnpmPackageBuilder = {
    enable = true;
    pnpmDepsHash = "sha256-q0PTXKAX0mhrMKMnFzV65YU948lh+/rGn9ttWzBfdNc=";
    sourceRoot = "source/bindings/nodejs";
    packages.build = with pkgs; [
      stdenv.cc # stdenvNoCC is not enough
      pkg-config
      nodejs
      cargo
      rustc
      rustPlatform.cargoSetupHook
      rustPlatform.cargoCheckHook
      writableTmpDirAsHomeHook
    ];
  };

  build.extraAttrs = {
    # napi writes contents
    postPatch = ''
      chmod -R u+w ../..
    '';

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit (pkgs.mypkgs.ironcalc) src;
      hash = pkgs.mypkgs.ironcalc-tools.cargoHash;
    };

    cargoRoot = "../..";

    checkPhase = ''
      pnpm run test
    '';

    installPhase = ''
      mkdir -p $out/lib/node_modules/@ironcalc/nodejs
      cp index.js index.d.ts package.json *.node $out/lib/node_modules/@ironcalc/nodejs/
    '';
  };
}
