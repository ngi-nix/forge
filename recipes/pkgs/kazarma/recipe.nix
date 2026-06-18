{
  config,
  pkgs,
  lib,
  ...
}:
{
  pkgs.kazarma = {
    version = "1.0.0-alpha.1-unstable-2025-12-24";
    description = "Matrix bridge to ActivityPub.";
    homePage = "https://kazar.ma";
    mainProgram = "kazarma";
    license = lib.licenses.agpl3Only;
    source = {
      git = "git:https://gitlab.com/technostructures/kazarma/kazarma.git?rev=46dbc8d29006896b6b14057c1d0feb39bd768865";
      submodules = true;
      hash = "sha256-N8JP9I35sMxOj5BPIrwsfMb+puL9GXwdksnJR5CDcwg=";
      patches = [
        ./cacert.patch
        ./cldr-data_dir.patch
        ./tzdata.patch
        ./matrix_domain.patch
      ];
    };
    build.beamMixReleaseBuilder = {
      enable = true;
      erlangVersion = "27";
      elixirVersion = "1_17";
      mixFodDepsHash = "sha256-nsTAsVoDPmKQVjybaTDu18UGtqsvBz/A5mzzLKBqAHY=";
      packages.build = [
        pkgs.cacert
        pkgs.nodejs
      ];
    };
    phases = {
      configure.script.pre = ''
        rm -r deps
      '';
      build.script.pre =
        let
          cldr = pkgs.fetchFromGitHub {
            owner = "elixir-cldr";
            repo = "cldr";
            tag = "v2.43.2";
            hash = "sha256-xSWZV4bDcy/P5sSDM7gvuaCLhk4bk3lL2/MB5cm5/PE=";
          };
        in
        ''
          mkdir -p cldr
          ln -s ${cldr}/priv/cldr/locales cldr/
        '';
      build.script.post = ''
        rm -r assets
        cp -r ${pkgs.kazarma-assets}/lib/node_modules/assets .
        npm run deploy --prefix ./assets
        mix do deps.loadpaths --no-deps-check, phx.digest
      '';
    };
  };

  pkgs.kazarma-assets = pkg: {
    inherit (config.pkgs.kazarma)
      source
      version
      license
      homePage
      ;
    phases = {
      unpack.sourceRoot = "kazarma-46dbc8d/assets";
      patch.patches = lib.mkForce [ assets/package.json.patch ];
    };
    build.npmPackageBuilder = {
      enable = true;
      npmDepsHash = "sha256-ygMFzDkl83cDh+72xuf/PyOBxIax2d58OSP+eeG+Na0=";
      packages.build = [
      ];
    };
    build.extraAttrs = {
      dontNpmBuild = true;
      dontCheckForBrokenSymlinks = true;
      npmFlags = [ "--include=dev" ];
    };
  };
}
