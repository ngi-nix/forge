{
  pkgs,
  config,
  lib,
  ...
}:
let
  recipe = config.pkgs.mwoffliner;
in
{
  pkgs.mwoffliner = {
    version = "1.17.5";
    description = "Crawls any recent MediaWiki wiki and packages it into an offline ZIM snapshot for local browsing.";
    homePage = "https://github.com/openzim/mwoffliner";
    mainProgram = "mwoffliner";
    license = lib.licenses.gpl3;

    source = {
      git = "github:openzim/mwoffliner/v${recipe.version}";
      hash = "sha256-aqhxcknSaOFZVUD7730vkyuG+H/zsD9pFdApl9cYGFU=";
    };

    build.builders.npm = {
      enable = true;
      npmDepsHash = "sha256-RWLtRUKNPXqjALc2WNDvRriUSgdcwbon4LivZC/CIeo=";
      packages.build = with pkgs; [
        pkg-config
      ];
      packages.run = with pkgs; [
        libzim
        vips
      ];
    };

    build.env.SHARP_FORCE_GLOBAL_LIBVIPS = 1;

    build.phases = {
      patch.script.pre = ''
        patchShebangs dev/build.sh
      '';

      patch.patches = [
        ./001-fix-file-type-deps.patch
      ];

      configure.script.pre = ''
        # see https://github.com/nix-community/nur-combined/blob/48e39a64b9a2f61f613c325b9743bcc6e46e0fb5/repos/milahu/pkgs/by-name/pr/project-nomad/package.nix#L66-L84
        # patch libzim to use the system libzim
        pushd node_modules/@openzim/libzim
        # use libzim via pkg-config
        substituteInPlace binding.gyp \
          --replace-fail \
            '"libzim_local": "false"' \
            '"libzim_local": "true"'
        npm run build
        rm -v build/Release/libzim.so || true
        popd

        # patch sharp to use the system libvips
        pushd node_modules/sharp
        npm run install --loglevel verbose --foreground-scripts
        popd

        linkBin(){
          mkdir -p "$(dirname "$2")"
          ln -sf "$1" "$2"
        }

        # patch other binaries used by imagemin to use the system binaries
        linkBin ${lib.getExe' pkgs.advancecomp "advpng"} node_modules/advpng-bin/vendor/advpng
        linkBin ${lib.getExe' pkgs.gifsicle "gifsicle"} node_modules/gifsicle/vendor/gifsicle
        linkBin ${lib.getExe' pkgs.jpegoptim "jpegoptim"} node_modules/jpegoptim-bin/vendor/jpegoptim
        linkBin ${lib.getExe' pkgs.libjpeg_turbo "jpegtran"} node_modules/jpegtran-bin/vendor/jpegtran
        linkBin ${lib.getExe' pkgs.optipng "optipng"} node_modules/optipng-bin/vendor/optipng
        linkBin ${lib.getExe' pkgs.pngquant "pngquant"} node_modules/pngquant-bin/vendor/pngquant
        linkBin ${lib.getExe' pkgs.libwebp "cwebp"} node_modules/cwebp-bin/vendor/cwebp
      '';
    };

    build.extraAttrs = {
      npmRebuildFlags = [ "--ignore-scripts" ];
    };

    test.script = ''
      mwoffliner --version | grep -q ${recipe.version}
    '';
  };
}
