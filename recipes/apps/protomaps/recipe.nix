{
  pkgs,
  ...
}:

{
  apps.protomaps = {
    displayName = "Protomaps";
    description = "Toolchain for creating and serving PMTiles map archives.";
    usage = ''
      Protomaps provides tools for working with PMTiles, a single-file archive
      format for tilesets that can be served directly from cloud storage.

      ## PMTiles CLI

      Inspect a PMTiles archive

      ```bash
      pmtiles show archive.pmtiles
      ```

      Convert MBTiles to PMTiles

      ```bash
      pmtiles convert input.mbtiles output.pmtiles
      ```

      ## PMTiles Viewer

      The _pmtiles-viewer_ service serves a web-based map viewer at
      [http://localhost:8080](http://localhost:8080).
    '';

    icon = ./icon.svg;

    links = {
      website = "https://protomaps.com/";
      source = "https://github.com/protomaps";
      docs = "https://docs.protomaps.com/";
    };

    ngi.grants = {
      Core = [
        "Protomaps"
      ];
    };

    programs = {
      packages = [
        pkgs.pmtiles
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    services = {
      components.pmtiles-viewer = {
        process.environment = {
          PMTILES_APP_ROOT = "${pkgs.pmtiles-viewer}/share/pmtiles-app";
        };
        process.configData."Caddyfile" = {
          source = ./Caddyfile;
          path = "Caddyfile";
        };
        process.command = pkgs.caddy;
        process.argv = [
          "run"
          "--adapter"
          "caddyfile"
          "--config"
          "$XDG_CONFIG_HOME/Caddyfile"
        ];
        process.ports = [ "8080:8080" ];
      };

      runtimes = {
        container = {
          enable = true;
        };

        nixos.enable = true;
      };
    };

    test = {
      programs.script = ''
        pmtiles version 2>&1 | grep -qi "pmtiles"
      '';

      services.script = ''
        curl="curl --retry 10 --retry-max-time 60 --retry-all-errors"
        $curl localhost:8080 | grep -qi "PMTiles viewer"
      '';
    };
  };
}
