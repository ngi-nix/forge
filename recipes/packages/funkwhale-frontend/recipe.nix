{
  config,
  lib,
  pkgs,
  ...
}:

{
  packages.funkwhale-frontend = {
    version = "2.0.2";
    description = "Frontend for the federated audio platform, Funkwhale.";
    homePage = "https://www.funkwhale.audio/";
    license = lib.licenses.agpl3Only;

    source = {
      url = "https://dev.funkwhale.audio/funkwhale/funkwhale/-/archive/2.0.2/funkwhale-2.0.2.tar.gz";
      hash = "sha256-8Oii3JR/c5GvvYwgZZfc8DEPdlZH2cWV2NcHu0usy40=";
      patches = [
        ./fix-signup-form-crash.patch
        ./yarn-4.14-support.patch
      ];
    };

    build.standardBuilder = {
      enable = true;
    };

    build.extraAttrs = {
      sourceRoot = "funkwhale-2.0.2/front";

      missingHashes = ./missing-hashes.json;

      offlineCache = pkgs.yarn-berry_4.fetchYarnBerryDeps {
        src = pkgs.fetchurl {
          inherit (config.packages.funkwhale-frontend.source) url hash;
        };
        inherit (config.packages.funkwhale-frontend.source) patches;
        sourceRoot = "funkwhale-2.0.2/front";
        missingHashes = ./missing-hashes.json;
        hash = "sha256-qY0yJk6IY8srLNJWSj4eBTuGoVFOBX8cc1QLODP8qMA=";
      };

      env = {
        CYPRESS_INSTALL_BINARY = 0;
        CYPRESS_RUN_BINARY = lib.getExe pkgs.cypress;
      };

      nativeBuildInputs = [
        pkgs.yarn-berry_4.yarnBerryConfigHook
        pkgs.yarn-berry_4
        pkgs.nodejs
        pkgs.dart-sass
      ];

      buildPhase = ''
        runHook preBuild
        substituteInPlace node_modules/sass-embedded/dist/lib/src/compiler-path.js \
            --replace-fail 'compilerCommand = (() => {' 'compilerCommand = (() => { return ["${lib.getExe pkgs.dart-sass}"];'
        yarn run build:deployment
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        cp -r dist $out
        runHook postInstall
      '';
    };
  };
}
