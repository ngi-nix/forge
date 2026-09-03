{
  lib,
  pkgs,
  ...
}:

{
  pkgs.pmtiles-viewer = {
    version = "0-unstable-2026-08-19";
    description = "Web viewer for PMTiles archives.";
    homePage = "https://docs.protomaps.com";
    license = lib.licenses.bsd3;

    source = {
      git = "github:protomaps/PMTiles/182d5b3cfdc2f5a6adbc54630c612da2f6086bdd";
      hash = "sha256-pjRiUCRqDR5N2ICBndboPfZHDjub8/UYhX9ZsBQ/iaE=";
    };

    build.npmPackageBuilder = {
      enable = true;
      npmDepsHash = "sha256-eKCXB6hpIywV+aS/ot6VwjJSL1wgqZ5H85A/bhinFEc=";
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
