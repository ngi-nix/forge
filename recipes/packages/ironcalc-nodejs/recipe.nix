{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Node.js bindings for IronCalc";

  inherit (systemConfig.forge.packages.ironcalc)
    homePage
    license
    source
    version
    ;

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
      inherit (systemConfig.packages.ironcalc) src;
      hash = systemConfig.packages.ironcalc-tools.cargoHash;
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
