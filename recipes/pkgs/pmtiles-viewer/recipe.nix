{
  lib,
  pkgs,
  ...
}:

{
  pkgs.pmtiles-viewer = {
    version = "0-unstable-2026-09-16";
    description = "Web viewer for PMTiles archives.";
    homePage = "https://protomaps.com/docs/pmtiles/";
    license = lib.licenses.bsd3;

    source = {
      git = "github:protomaps/PMTiles/aec8fa1341222fdddb3318e9ffa8e18e19b312f7";
      hash = "sha256-75hCWdmN94er7ZcdO3SKmGPjKoDPZKdvJugvKo43uVA=";
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
