{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Ironcalc wasm bindings";

  inherit (rootConfig.forge.packages.ironcalc)
    homePage
    license
    source
    version
    ;

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
