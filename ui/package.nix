{
  lib,
  buildElmApplication,
  fetchzip,
  jq,
  linkFarm,
  symlinkJoin,
  esbuild,

  appIcons,
  appWasm,

  _forge,
  highlight-js,
  ...
}:

let
  main = buildElmApplication {
    pname = "forge-ui-elm";
    version = "0.1.0";
    src = ./.;
    elmLock = ./elm.lock;
    entry = [ "src/Main.elm" ];
    output = "js/Elm.js";
    doMinification = true;
    useTerser = true;
    enableOptimizations = true;
  };

  defaultIcon = ./src/app-icon.svg;

  bootstrapCss = fetchzip rec {
    pname = "bootstrap";
    # TODO updateScript
    version = "5.3.8";
    url = "https://github.com/twbs/bootstrap/releases/download/v${version}/bootstrap-${version}-dist.zip";
    hash = "sha256-StRhHJIRGzguLlo0BGOAMy0PCCmMovzgU/5xZJgVrqQ=";
  };

  browserWasiShim = fetchzip rec {
    pname = "browser_wasi_shim";
    version = "0.4.2";
    url = "https://registry.npmjs.org/@bjorn3/browser_wasi_shim/-/browser_wasi_shim-${version}.tgz";
    hash = "sha256-lfKZk1ZFchBCqon+Pr+PoT1Kb6Hq8O+0NKsalWEfCnI=";
  };

  # `NODE_PATH` for esbuild
  nodeModules = linkFarm "forge-ui-node-modules" [
    {
      name = "@bjorn3/browser_wasi_shim";
      path = browserWasiShim;
    }
  ];
in
symlinkJoin {
  name = "forge-ui";
  paths = [ main ];
  postBuild = ''
    pushd $out

    # Copy static files
    cp ${./src/index.html} index.html
    cp ${./src/404.html} 404.html
    cp ${./src/favicon.svg} favicon.svg

    mkdir -p css js/src

    cp -aR ${./src/css}/. css
    cp -aR ${./src/js}/. js/src

    chmod -R u+w css js

    install -D ${bootstrapCss}/css/bootstrap.min.css bootstrap/css/bootstrap.min.css
    install -D ${highlight-js}/theme.css css/highlightjs-theme.css

    install -D ${highlight-js}/highlight.min.js js/highlight.min.js

    # Rename minimized Elm output
    mv js/Elm.min.js js/Elm.js

    export NODE_PATH=${nodeModules}
    ${esbuild}/bin/esbuild --bundle --outfile=js/main.js --minify js/src/main.js
    ${esbuild}/bin/esbuild --bundle --outfile=js/WasiWorker.js --minify js/src/WasiWorker.js
    rm -rf js/src

    # Symlink config files
    ln -s ${_forge.config} forge-config.json
    ln -s ${_forge.options} forge-options.json

    # Create resources directory and copy default icon
    mkdir -p resources/apps
    cp ${defaultIcon} resources/apps/app-icon.svg

    # Process each app: copy icons and create HTML routes
    for app in $(${lib.getExe jq} '.apps.[].name' -r forge-config.json); do
      # Copy custom icon if it exists, otherwise use default
      mkdir -p "resources/apps/$app"
      if [ -f "${appIcons}/$app/icon.svg" ]; then
        cp "${appIcons}/$app/icon.svg" "resources/apps/$app/icon.svg"
      fi

      # Copy the WASI program of the browser runtime if it exists
      if [ -d "${appWasm}/$app" ]; then
        cp "${appWasm}/$app"/*.wasm "resources/apps/$app/"
      fi

      # Create SPA routing for this app (github pages workaround)
      mkdir -p "app/$app"
      ln -s $out/index.html "app/$app/index.html"

      # For backward compatibility with the -app namespace
      mkdir -p "app/$app-app"
      ln -s $out/index.html "app/$app-app/index.html"
    done

    for page in apps pkgs recipe recipe/options; do
      mkdir -p "$page"
      ln -s $out/index.html "$page/index.html"
    done

    # Install docs
    ln -s ${_forge.docs} docs

    popd
  '';
  passthru = { inherit bootstrapCss nodeModules; };
}
