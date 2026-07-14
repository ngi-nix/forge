{
  lib,
  pkgs,
  ...
}:

{
  pkgs.wormhole-wasm = {
    version = "0.5.4-beta";
    description = "Wormhole WASM module for Winden.";
    homePage = "https://github.com/LeastAuthority/wormhole-william";
    license = lib.licenses.mit;

    source = {
      git = "github:LeastAuthority/wormhole-william/10940cd31c7445ede9561db3ef08f566d95b5f3e";
      hash = "sha256-yvdUk30va1fn3dZPgQ7Wa4+6vWiZiAngDffxgtscjeY=";
    };

    build.goPackageBuilder = {
      enable = true;
      vendorHash = "sha256-G0ARZwnRt2DFJSa2qdw3mEunIEpsu9kPxDwqUq+NIIM=";
    };

    build.extraAttrs = {
      buildPhase = ''
        GOOS=js GOARCH=wasm go build -buildvcs=false -o wormhole.wasm ./wasm/module
      '';

      installPhase = ''
        mkdir -p $out
        cp wormhole.wasm $out/
      '';
    };
  };

  pkgs.winden = {
    version = "0.5.4-beta";
    description = "Securely transfer files between computers via the browser.";
    homePage = "https://winden.app";
    mainProgram = "winden";
    license = lib.licenses.mit;

    source = {
      git = "github:LeastAuthority/winden/0.5.4-beta";
      hash = "sha256-eAJpZ1uKrakb/1yZ16E3nA2IJVNNPpRUDWMUXiapIEg=";
    };

    build.npmPackageBuilder = {
      enable = true;
      npmDepsHash = "sha256-jCMWlUMqMCf3yOVxr/SlYVvQsCpAp2CU08lAcdXlNvQ=";
      npmInstallFlags = [ "--legacy-peer-deps" ];
    };

    build.extraAttrs = {
      sourceRoot = "source/client";
      nativeBuildInputs = [ pkgs.go ];
      npmFlags = [ "--legacy-peer-deps" ];
      env.SENTRYCLI_SKIP_DOWNLOAD = "1";

      dontNpmBuild = true;

      buildPhase = ''
        mkdir -p dist
        cp ${pkgs.wormhole-wasm}/wormhole.wasm dist/wormhole.wasm
        sed -i 's|$(go env GOROOT)/misc/wasm/wasm_exec.js|$(find $(go env GOROOT) -name wasm_exec.js \| head -n 1)|g' gulpfile.js
        NODE_ENV=production npx gulp prepWorker public javascript worker
      '';

      installPhase = ''
        mkdir -p $out/share/winden
        cp -r dist/* $out/share/winden/
      '';
    };
  };
}
