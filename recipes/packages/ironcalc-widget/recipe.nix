{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Ironcalc frontend widget package";

  inherit (systemConfig.forge.packages.ironcalc)
    homePage
    license
    source
    version
    ;

  build.npmPackageBuilder = {
    enable = true;
    npmDepsHash = "sha256-jPnUUEOjW9WHVjpBH/qKB4P5RuMI0uvjog8C41cPQdY=";
    packages.build = [
      systemConfig.packages.ironcalc-wasm
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
      cp -rv ${systemConfig.packages.ironcalc-wasm}/. ../../bindings/wasm/pkg/
    '';

    # copy instead of symlinking to avoid noBrokenSymlinks check failing in fixupPhase.
    preBuild = ''
      rm -rf node_modules/@ironcalc/wasm
      mkdir -p node_modules/@ironcalc
      cp -rv ${systemConfig.packages.ironcalc-wasm}/. node_modules/@ironcalc/wasm
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
