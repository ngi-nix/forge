{
  lib,
  pkgs,
  ...
}:

{
  pkgs.pmtiles-viewer = {
    version = "0-unstable-2026-05-26";
    description = "Web viewer for PMTiles archives.";
    homePage = "https://protomaps.com/docs/pmtiles/";
    license = lib.licenses.bsd3;

    source = {
      git = "github:protomaps/PMTiles/8b8ddea4dbff1b0104cf2bebf2f7ff35c91b41d5";
      hash = "sha256-QEcS+HNizUvXP/5oOzJFeOcKfgeRHHkFhGQjb01HQWI=";
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
