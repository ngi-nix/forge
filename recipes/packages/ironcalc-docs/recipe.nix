{
  systemConfig,
  lib,
  pkgs,
  ...
}:

{
  description = "Ironcalc documentation site";

  inherit (systemConfig.forge.packages.ironcalc)
    homePage
    license
    source
    version
    ;

  build.npmPackageBuilder = {
    enable = true;
    npmDepsHash = "sha256-lH4HUUiVSGcF/5cSse0l2ZWial3tkwOO8peb5Wl35rI=";
    packages.build = [
      pkgs.gitMinimal
    ];
  };

  build.extraAttrs = {
    postPatch = ''
      cd docs
    '';

    # Icons are expected in public/
    # https://discourse.nixos.org/t/nix-build-of-vuepress-project-is-slow-or-hangs/56521/5
    buildPhase = ''
      mkdir -p src/public
      cp -v src/*.svg src/*.png src/public/ || true

      npm run build > tmp 2>&1
    '';

    installPhase = ''
      mkdir -p $out/share/doc/ironcalc
      cp -r src/.vitepress/dist/* $out/share/doc/ironcalc/
    '';
  };
}
