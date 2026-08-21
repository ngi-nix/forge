{
  lib,
  pkgs,
  ...
}:

{
  pkgs.pmtiles-viewer = {
    version = "0-unstable-2026-08-10";
    description = "Web viewer for PMTiles archives.";
    homePage = "https://docs.protomaps.com";
    license = lib.licenses.bsd3;

    source = {
      git = "github:protomaps/PMTiles/3b10e67edb65c6b04549f74c0279cef8328d859c";
      hash = "sha256-4eRnU4ktv39GGwyrzK1fAt7Im/46G/i/QzNIGddKtao=";
    };

    build.npmPackageBuilder = {
      enable = true;
      npmDepsHash = "sha256-RgzbzEzZtHrLwC+BSYwnh54ylgqfqfqO44BkCYpVnxs=";
    };

    build.extraAttrs = {
      sourceRoot = "source/app";

      installPhase = ''
        runHook preInstall
        mkdir -p $out/share/pmtiles-app
        cp -r dist/* $out/share/pmtiles-app/
        runHook postInstall
      '';
    };

    test.script = ''
      file "${pkgs.pmtiles-viewer}/share/pmtiles-app/index.html" \
      | grep "HTML document, ASCII text"
    '';
  };
}
