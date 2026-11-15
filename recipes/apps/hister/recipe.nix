{
  config,
  forge-lib,
  pkgs,
  ...
}:

let
  app = config.apps.hister;
  port = toString app.services.components.hister.endpoints.web.port;
in
{
  pkgs.hister = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.hister;
    };
  };

  apps.hister = {
    displayName = "Hister";
    description = "Self-hosted search platform for web history and stored files.";
    categories = with forge-lib.categories; [
      Archiving
      Network
    ];
    longDescription = ''
      Hister is a private, self-hosted search engine for visited websites and
      stored files, combining full-text search with automatic capture and imports.

      Hister uses a client and server architecture. The server stores and searches documents.
      Clients collect content or run searches. The hister program can act as both, while the browser extension is a client.
    '';
    usage = ''
      First, launch the app [in a container](app/${app.name}#run-container) or [in a NixOS VM](app/${app.name}#run-nixos).

      ##### Web Interface

      Open the [web interface](http://localhost:${toString app.services.components.hister.endpoints.web.forwardedPort}) to search and browse indexed history.

      ##### Importing history

      Content can come from the browser extension, imported browser history or bookmarks, watched directories, crawlers, or API clients.

      See [Browser Ingestion](https://hister.org/docs/browser-ingestion) to choose how to collect content.

      Enter the [shell environment](app/${app.name}#run-shell) to add `hister` to PATH.

      ##### Browser History Import

      Hister detects a supported browser database, reads qualifying URLs, and asks its crawler to fetch the pages that exist now.
      The import does not inherit the browser session. Sites that need login cookies may return a login page or reject the request.

      ```console
      hister import browser
      ```

      Read [docs](https://hister.org/docs/import#importing-browser-history) for more.

      ##### Browser Extension Capture

      See [https://hister.org/docs/browser-extension](https://hister.org/docs/browser-extension)

      ##### Browser Bookmark Import

      Import saved bookmarks from Firefox based browsers, Chromium based browsers, or Ladybird:

      ```console
      hister import browser bookmarks
      hister import browser bookmarks --browser firefox
      ```
    '';

    links = {
      website = "https://hister.org";
      docs = "https://hister.org/docs";
      source = "https://github.com/asciimoo/hister";
    };

    ngi.grants = {
      Commons = [
        "Hister"
      ];
    };

    icon = ./icon.svg;

    services = {
      components.hister = {
        process = {
          command = pkgs.hister;
          argv = [
            "listen"
            "-a"
            "0.0.0.0:${port}"
            "-u"
            "http://localhost:${port}"
          ];
          environment = {
            HISTER_DATA_DIR = "/var/lib/hister";
          };
        };

        healthcheck = {
          enable = true;
          test = [
            "curl"
            "-fs"
            "http://localhost:${port}/healthz"
          ];
          packages = [ pkgs.curl ];
          interval = "60s";
          timeout = "3s";
          startPeriod = "10s";
          retries = 10;
        };

        endpoints = {
          web = {
            port = 4433;
          };
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.hister = {
            packages = [
              pkgs.bash
              pkgs.coreutils
              pkgs.hister
            ];
          };
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.hister
          ];
        };
      };
    };

    programs = {
      packages = [ pkgs.hister ];
      runtimes.shell.enable = true;
    };

    test.services = {
      packages = [
        pkgs.curl
        pkgs.hister
      ];
      script = ''
        curl="curl --retry 10 --retry-max-time 120 --retry-all-errors -fs"

        $curl localhost:${port}/healthz
        $curl localhost:${port}/ | grep "<title>Hister</title>"
        $curl localhost:${port}/api/config | grep '"title":"Hister"'
      '';
    };
  };
}
