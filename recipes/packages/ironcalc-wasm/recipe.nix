{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ironcalc-wasm";
  version = "0.7.1-unstable-2026-04-29";
  description = "Ironcalc wasm bindings.";
  homePage = "https://www.ironcalc.com";
  license = with lib.licenses; [
    mit
    asl20
  ];

  source = {
    git = "github:ironcalc/ironcalc/8461ff71347ab19145cd7ad50ef829181ba765c2";
    hash = "sha256-vjI3M+hS9bXK8QQlopAy6f4dCISfQHGMvN9sMNKp88Q=";
  };

  build.rustPackageBuilder = {
    enable = true;
    cargoHash = "sha256-q5DnqhIYKUUqfJ4/TNHYF1QgTbH198QtgirQ+lP30wk=";
    packages.build = [
      pkgs.binaryen
      pkgs.pkg-config
      pkgs.python3
      pkgs.wasm-bindgen-cli_0_2_108
      pkgs.wasm-pack
      pkgs.nodejs
      pkgs.typescript
      pkgs.lld
      pkgs.writableTmpDirAsHomeHook
    ];
    packages.run = [
      pkgs.bzip2
      pkgs.zstd
    ];
  };

  build.extraAttrs = {
    buildPhase = ''
      cd bindings/wasm
      # skip tests for now
      # make tests

      wasm-pack build --target web --scope ironcalc --release
      cp README.pkg.md pkg/README.md
      tsc types.ts --target esnext --module esnext
      python3 fix_types.py
      rm -f types.js

      # wasm-pack generates a package.json, we must provide one
      cat > pkg/package.json <<EOF
      {
        "name": "@ironcalc/wasm",
        "version": "${config.version}",
        "type": "module",
        "files": [
          "wasm_bg.wasm",
          "wasm.js",
          "wasm.d.ts"
        ],
        "main": "wasm.js",
        "module": "wasm.js",
        "types": "wasm.d.ts",
        "exports": {
          ".": {
            "types": "./wasm.d.ts",
            "import": "./wasm.js"
          }
        },
        "sideEffects": false
      }
      EOF
    '';

    installPhase = ''
      cp -r pkg $out
    '';
  };
}
