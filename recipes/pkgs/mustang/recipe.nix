{
  pkgs,
  config,
  lib,
  ...
}:
let
  recipe = config.pkgs.mustang;
  electron = pkgs.electron_41;
in
{
  pkgs.mustang = {
    version = "0.9.38";
    description = "Full-featured desktop email, chat, video conference, calendar and contacts client.";
    homePage = "https://www.mustang.im";
    mainProgram = "mustang";
    license = lib.licenses.eupl12;

    source = {
      git = "github:mustang-im/mustang/v${recipe.version}";
      hash = "sha256-vW7JueYkmmIxAcGq9UACH2WC55rH3ugoVWkRCTtSD7Q=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = with pkgs; [
        yarn
        nodejs_24
        fixup-yarn-lock
        writableTmpDirAsHomeHook # for yarn cache
        python3 # for node-gyp
        makeWrapper
        copyDesktopItems
        perl # for mustang-brand.sh
      ];
    };

    build.extraAttrs = {
      # None of app/, desktop/, desktop/backend/, lib/ ship a yarn.lock
      # upstream.
      # yarn.lock file is generated via a synthetic root package.json:
      #
      # {
      #   "name": "mustang-synthetic-root",
      #   "private": true,
      #   "workspaces": [
      #     "app",
      #     "desktop",
      #     "desktop/backend",
      #     "lib"
      #   ],
      #   "resolutions": {
      #     "vite": "^7.3.1"
      #   }
      # }
      #
      # to get a single merged lockfile / fetchYarnDeps cache instead of one
      # per subdir.
      #
      # How to update yarn.lock file:
      #
      # nix develop .#pkgs.mustang.env
      # cp -r --no-preserve=mode,ownership /nix/store/<hash>-source src
      # yarn install --mode=update-lockfile --ignore-scripts
      # cp yarn.lock ../recipes/pkgs/mustang/yarn.lock
      yarnDeps = pkgs.fetchYarnDeps {
        yarnLock = ./yarn.lock;
        hash = "sha256-n7HBQbZSYbWlMcxIhfVNniE6lnJONxUdeTCNW14uggA=";
      };

      postPatch = ''
        (cd app/build && sh mustang-brand.sh);

        cp ${./yarn.lock} "$PWD/yarn.lock"
        chmod u+rw "$PWD/yarn.lock"
        fixup-yarn-lock "$PWD/yarn.lock"

        for d in app desktop desktop/backend lib; do
          ln -sf "$PWD/yarn.lock" "$d/yarn.lock"
        done
      '';

      buildPhase = ''
        runHook preBuild
        yarn config set yarn-offline-mirror "${recipe.build.extraAttrs.yarnDeps}"

        for d in app desktop desktop/backend lib; do
          (cd "$d" && yarn install --offline --frozen-lockfile --ignore-engines --ignore-scripts)
          patchShebangs "$d/node_modules"
        done

        pushd desktop

        export npm_config_nodedir="${electron.headers}"
        npx electron-rebuild \
          --version "${electron.version}" \
          --build-from-source \
          --force

        npx electron-vite build

        npx electron-builder \
          --linux dir \
          -c.asar=true \
          -c.npmRebuild=false \
          -c.electronDist="${electron.dist}" \
          -c.electronVersion="${electron.version}"

        popd

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/opt/mustang
        cp -a desktop/dist/linux-unpacked/resources/ $out/opt/mustang/
        makeWrapper "${lib.getExe electron}" "$out/bin/mustang" \
          --inherit-argv0 \
          --set ELECTRON_FORCE_IS_PACKAGED 1 \
          --add-flags "$out/opt/mustang/resources/app.asar"

        install -Dm644 desktop/build/icon.svg "$out/share/icons/hicolor/scalable/apps/mustang.svg"

        copyDesktopItems

        runHook postInstall
      '';

      desktopItems = [
        (pkgs.makeDesktopItem {
          name = "mustang";
          desktopName = "Mustang";
          exec = "mustang %U";
          type = "Application";
          icon = "mustang";
          startupWMClass = "Mustang";
          comment = "Mustang - Video conference, chat, mail, calendar, files, contacts";
          categories = [ "Network" ];
          mimeTypes = [
            "message/rfc822"
            "x-scheme-handler/mailto"
          ];
          terminal = false;
        })
      ];
    };
  };
}
