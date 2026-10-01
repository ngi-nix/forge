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
    version = "unstable-2025-06-05";
    description = "Securely transfer files between computers via the browser.";
    homePage = "https://winden.app";
    mainProgram = "winden";
    license = lib.licenses.mit;

    source = {
      git = "github:LeastAuthority/winden/0082e5aeef7eef5d4ae163f2ce61906bd2ee4e0a";
      hash = "sha256-AVinNoLcSmPBMHowwSLdenHdN8kxmyEhUP07JEDtUXs=";
      patches = [
        ./0001-use-git-for-magic-wormhole.patch
        ./0002-webpack-wasm-bindgen.patch
        ./0003-webpack-env.patch
      ];
    };

    build.npmPackageBuilder = {
      enable = true;
      npmDepsHash = "sha256-zxxMxtA9KkNt0LMPJPw+v1kerLC+I8wgUfO6QYjGY48=";
      npmInstallFlags = [
        "--legacy-peer-deps"
        "--omit=optional"
      ];
    };

    build.extraAttrs = {
      sourceRoot = "source/client";
      nativeBuildInputs = with pkgs; [
        cargo
        rustc
        wasm-pack
        wasm-bindgen-cli_0_2_99
        lld
        binaryen
        rustPlatform.cargoSetupHook
      ];
      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        name = "winden-cargo-deps-0.2.99";
        src = pkgs.applyPatches {
          name = "source";
          src = pkgs.winden.src;
          sourceRoot = "source/client";
          patches = [
            ./0001-use-git-for-magic-wormhole.patch
            ./0002-webpack-wasm-bindgen.patch
            ./0003-webpack-env.patch
          ];
        };
        sourceRoot = "source/wasm";
        hash = "sha256-ZCJWAqx/64PhJMVOKxZsf29NgBW9nKlYlbsWLAJLTSM=";
      };
      cargoRoot = "wasm";

      makeCacheWritable = true;
      npmDepsFetcherVersion = 2;
      SENTRYCLI_SKIP_DOWNLOAD = "1";
      RUSTFLAGS = "-C target-feature=-reference-types,-multivalue,-bulk-memory,-mutable-globals,-nontrapping-fptoint,-sign-ext";

      postPatch = ''
        npmConfigHook() {
          echo "Bypassing default npmConfigHook..."
        }
      '';

      configurePhase = ''
        runHook preConfigure

        export HOME=$(mktemp -d)
        export npm_config_cache=$(mktemp -d)
        cp -r "$npmDeps"/* "$npm_config_cache"
        chmod -R +w "$npm_config_cache"

        npm install --cache "$npm_config_cache" --offline --ignore-scripts --no-audit --legacy-peer-deps --omit=optional

        patchShebangs node_modules

        runHook postConfigure
      '';

      buildPhase = ''
        export HOME=$(mktemp -d)
        touch .env

        cargo build --manifest-path ./wasm/Cargo.toml --target wasm32-unknown-unknown --release
        wasm-bindgen ./wasm/target/wasm32-unknown-unknown/release/wormhole_rs_wasm.wasm --out-dir pkg --target web
        wasm-opt -O pkg/wormhole_rs_wasm_bg.wasm -o pkg/wormhole_rs_wasm_bg.wasm

        cat <<EOF > pkg/package.json
        {
          "name": "wormhole-rs-wasm",
          "version": "0.1.0",
          "main": "wormhole_rs_wasm.js",
          "module": "wormhole_rs_wasm.js",
          "types": "wormhole_rs_wasm.d.ts",
          "sideEffects": [
            "./wormhole_rs_wasm.js",
            "./wormhole_rs_wasm_bg.wasm"
          ]
        }
        EOF

        export MAILBOX_URL="''${MAILBOX_URL:-ws://127.0.0.1:8080/mailbox/v1}"
        export RELAY_URL="''${RELAY_URL:-ws://127.0.0.1:8080/relay}"
        npm run build
      '';

      installPhase = ''
        mkdir -p $out/share/winden
        cp -r dist/* $out/share/winden/
      '';
    };
  };
}
