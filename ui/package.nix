{
  buildElmApplication,
  fetchzip,
  jq,
  symlinkJoin,

  _forge-config,
  _forge-options,
  appIcons,
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
    enableOptimizations = true;
  };

  agentsFile = ../AGENTS.md;

  defaultIcon = ./src/app-icon.svg;

  bootstrapCss = fetchzip rec {
    pname = "bootstrap";
    version = "5.3.8";
    url = "https://github.com/twbs/bootstrap/releases/download/v${version}/bootstrap-${version}-dist.zip";
    hash = "sha256-StRhHJIRGzguLlo0BGOAMy0PCCmMovzgU/5xZJgVrqQ=";
  };
in
symlinkJoin {
  name = "forge-ui";
  paths = [ main ];
  postBuild = ''
    pushd $out

    # Copy static files
    cp ${./src/index.html} index.html
    cp ${./src/favicon.svg} favicon.svg
    cp -aR ${./src/css}/. css
    cp -aR ${./src/js}/. js
    chmod -R u+w css js
    install -D ${bootstrapCss}/css/bootstrap.min.css bootstrap/css/bootstrap.min.css

    # Rename minimized Elm output
    mv js/Elm.min.js js/Elm.js

    # Symlink config files
    ln -s ${_forge-config} forge-config.json
    ln -s ${_forge-options} forge-options.json

    # Create resources directory and copy default icon
    mkdir -p resources/apps
    cp ${defaultIcon} resources/apps/app-icon.svg

    # Process each app: copy icons and create HTML routes
    for app in $(${jq}/bin/jq '.apps.[].name' -r forge-config.json); do
      # Remove -app suffix for directory name
      app_dir="''${app%-app}"

      # Copy custom icon if it exists, otherwise use default
      mkdir -p "resources/apps/$app_dir"
      if [ -f "${appIcons}/$app_dir/icon.svg" ]; then
        cp "${appIcons}/$app_dir/icon.svg" "resources/apps/$app_dir/icon.svg"
      else
        cp ${defaultIcon} "resources/apps/$app_dir/icon.svg"
      fi

      # Create SPA routing for this app (github pages workaround)
      mkdir -p "app/$app_dir"
      ln -s $out/index.html "app/$app_dir/index.html"
    done

    for page in apps packages recipe recipe/options; do
      mkdir -p "$page"
      ln -s $out/index.html "$page/index.html"
    done

    popd
  '';
  passthru = { inherit bootstrapCss; };
}
