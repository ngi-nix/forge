{
  config,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.docspec;
in

{
  apps.docspec = {
    displayName = "DocSpec";
    description = "Document conversion SDK for rich text formats.";
    usage = ''
      ##### Convert document with CLI

      First, [launch the shell envrionment](app/${app.name}#run-shell) containing `${app.name}`.

      Then, clone the project repository:

      ```bash
      git clone ${app.links.source} docspec
      cd docspec
      ```

      Next, convert one of the test documents to a BlockNote JSON, since it's currently the best-supported output format:

      ```bash
      ${app.data.testProgram}
      ```

      For a list of supported formats and their status, run:

      ```bash
      docspec convert --help
      ```

      ##### Convert document with server

      First, launch the app [in a container](app/${app.name}#run-container) or [in a NixOS VM](app/${app.name}#run-nixos).

      Then, send a markdown document to the server:

      ```bash
      ${app.data.testService}
      ```

      For more information regarding the endpoint, header and format reference, see the [`docspec-http`](${app.links.source}/tree/main/crates/docspec-http) page.
    '';

    data = {
      mainPort = "3030";
      testProgram = "docspec convert tests/fixtures/docx/pandoc/headers.docx --output blocknote.json";
      testService = ''
        curl -X POST http://localhost:${app.data.mainPort}/conversion \
             -H 'Content-Type: text/markdown' \
             -d '# Hello' '';
    };

    links = {
      website = "https://github.com/docspec/docspec";
      source = "https://github.com/docspec/docspec";
      docs = null;
    };

    ngi.grants = {
      Commons = [
        "DocSpec-WASM"
      ];
    };

    programs = {
      mainPackage = pkgs.docspec;
      packages = [ pkgs.docspec ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    services = {
      components.docspec = {
        process.command = pkgs.docspec;
        process.argv = [
          "http"
          "--host"
          "0.0.0.0"
          "--port"
          "${app.data.mainPort}"
        ];
        process.ports = [
          "${app.data.mainPort}:${app.data.mainPort}"
        ];
        healthcheck = {
          enable = true;
          test = [
            "${lib.getExe pkgs.curl}"
            "-fs"
            "http://localhost:${app.data.mainPort}/health"
          ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "10s";
          retries = 10;
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.docspec = {
            packages = with pkgs; [
              docspec
              coreutils
              bash
            ];
          };
        };

        nixos = {
          enable = true;
          packages = with pkgs; [
            docspec
          ];
        };
      };
    };

    test = {
      programs.script = ''
        cp -r ${pkgs.docspec.src}/. .
        ${app.data.testProgram}
      '';
      services.script = ''
        alias curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"
        ${app.data.testService}
      '';
    };
  };
}
