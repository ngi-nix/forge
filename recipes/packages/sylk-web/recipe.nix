{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "sylk-web";
  version = "3.8.0";
  description = "Web client for SylkServer - multiparty videoconferencing";
  homePage = "https://sylkserver.com/";
  mainProgram = "sylk-web";
  license = lib.licenses.agpl3Plus;

  source = {
    git = "github:AGProjects/sylk-webrtc/3.8.0";
    hash = "sha256-AJbZDAEqGfVPuo+My8wxfFWVPelO6XK2pKsglmLyRTw=";
  };

  build.standardBuilder = {
    enable = true;
    packages.build = with pkgs; [
      fixup-yarn-lock
      makeWrapper
      nodejs
      yarn
    ];
  };

  build.extraAttrs = {
    dontConfigure = true;

    yarnOfflineCache = pkgs.fetchYarnDeps {
      yarnLock = pkgs.mypkgs.sylk-web.src + "/yarn.lock";
      hash = "sha256-VY97NPnT1225l6SLyTI3qITBGF7rqE5xz6UVVucblcU=";
    };

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR

      fixup-yarn-lock yarn.lock
      yarn config --offline set yarn-offline-mirror "$yarnOfflineCache"
      yarn install --offline --frozen-lockfile --ignore-engines --ignore-scripts
      patchShebangs node_modules/

      # set up posthtmlrc for non-electron build
      cp .posthtmlrc_no_electron .posthtmlrc

      # run parcel directly, bypassing prebuild lint
      npx parcel build ./src/index.html --no-source-maps

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/sylk-web
      cp -R dist/* $out/share/sylk-web/

      runHook postInstall
    '';

    postFixup = ''
      makeWrapper ${lib.getExe pkgs.serve} $out/bin/sylk-web \
        --prefix PATH : ${lib.makeBinPath [ pkgs.xsel ]} \
        --chdir $out/share/sylk-web
    '';
  };

  test.script = ''
    test -f ${pkgs.mypkgs.sylk-web}/share/sylk-web/index.html
  '';
}
