{
  packages.ironcalc-docs =
    {
      lib,
      pkgs,
      ...
    }:

    {
      version = "0.7.1-unstable-2026-04-29";
      description = "Ironcalc documentation site";
      homePage = "https://docs.ironcalc.com";
      license = with lib.licenses; [
        mit
        asl20
      ];

      source = {
        git = "github:ironcalc/ironcalc/8461ff71347ab19145cd7ad50ef829181ba765c2";
        hash = "sha256-vjI3M+hS9bXK8QQlopAy6f4dCISfQHGMvN9sMNKp88Q=";
      };

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
    };
}
