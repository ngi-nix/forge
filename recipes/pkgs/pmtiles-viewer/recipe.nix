{
  lib,
  pkgs,
  ...
}:

{
  pkgs.pmtiles-viewer = {
    version = "0-unstable-2026-09-11";
    description = "Web viewer for PMTiles archives.";
    homePage = "https://protomaps.com/docs/pmtiles/";
    license = lib.licenses.bsd3;

    source = {
      git = "github:protomaps/PMTiles/35eaacfe5e37bbc91a47e6fa11f8f1c0224131ae";
      hash = "sha256-ec0zy3AGSaOM8M8bWoHCVeIbQg8gY5iwRVX058m41ko=";
    };

    build.npmPackageBuilder = {
      enable = true;
      npmDepsHash = "sha256-JLHIlQKGrNXHyRT/VhQznF8elLl4xAa1XTSfLFfQrLU=";
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
