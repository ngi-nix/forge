{
  config,
  pkgs,
  forge-lib,
  lib,
  ...
}:

let
  app = config.apps.dep-scan;
  usageSnippets = forge-lib.snippets.usage app;
in

{
  pkgs.dep-scan = {
    build.builders.identity = {
      enable = true;
      # TODO: fix description to have < 120 chars in nixpkgs or leave this as is.
      derivation = pkgs.pkgsOriginal.dep-scan.overrideAttrs (prev: {
        meta = prev.meta // {
          description = "Fully open-source security and license audit for application dependencies and container images.";
        };
      });
    };
  };

  apps.dep-scan = {
    displayName = "dep-scan";
    description = "Fully open-source security and license audit for application dependencies and container images.";
    categories = with forge-lib.categories; [
      Development
      Security
    ];
    icon = ./icon.svg;
    longDescription = ''
      Next-generation security and risk audit tool based on known vulnerabilities, advisories, and license limitations for project dependencies and container images.

      Supports reachability analysis, SBOM generation, and VEX creation.
    '';
    usage = ''
      ##### Scan a local project

      First, ${usageSnippets.run-shell}.

      Then navigate to the project directory you want to scan:

      ```bash
      cd /path/to/project
      ```

      Generate an SBOM and audit dependencies for vulnerabilities:

      ```bash
      depscan --src ./ --reports-dir ./reports
      ```

      You can also specify the project type explicitly (e.g., `nodejs`, `python`, `java`, `golang`, `rust`):

      ```bash
      depscan --src ./ -o ./reports -t python
      ```

      ##### Audit a CycloneDX SBOM file

      If you already have a CycloneDX SBOM (for example, produced by `cdxgen`):

      ```bash
      depscan --bom bom.json -o ./reports
      ```

      ##### Scan a container image

      Scan a container image directly:

      ```bash
      depscan --src <image-name>:latest -o ./reports -t docker
      ```

      ##### dep-scan server

      First, ${usageSnippets.run-container} or ${usageSnippets.run-nixos}.
      By default, the API will be accessible at `http://127.0.0.1:${toString app.parameters.port}`, but you can change this with the `port` parameter.

      To audit an SBOM file or project directory using the server:

      ```bash
      curl -X POST \
        -H "Content-Type: application/json" \
        -d '{"path": "/path/to/project/bom.json", "type": "js"}' \
        http://127.0.0.1:${toString app.parameters.port}/scan
      ```

      Or upload an SBOM file directly:

      ```bash
      curl -X POST \
        -H "Content-Type: multipart/form-data" \
        -F 'file=@bom.json' \
        "http://127.0.0.1:${toString app.parameters.port}/scan?type=js"
      ```

      ${usageSnippets.see-docs}
    '';

    links = {
      website = "https://github.com/owasp-dep-scan/dep-scan";
      source = "https://github.com/owasp-dep-scan/dep-scan";
      docs = "https://depscan.readthedocs.io";
    };

    ngi.grants = {
      Core = [
        "dep-scan"
      ];
      Commons = [
        "dep-scan-memory"
      ];
    };

    programs = {
      mainPackage = pkgs.dep-scan;
      packages = with pkgs; [
        dep-scan
        cdxgen
      ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    parameters = {
      port = {
        value = 7070;
        description = "Port of the dep-scan server API.";
      };
    };

    services = {
      components.dep-scan = {
        process.command = pkgs.dep-scan;
        process.argv = [
          "--server"
          "--server-host"
          "0.0.0.0"
          "--server-port"
          (toString app.parameters.port)
        ];
        process.environment = {
          DEPSCAN_SERVER_ALLOW_UNAUTHENTICATED_BIND = "true";
          HOME = "/tmp";
          VDB_HOME = "/tmp/vdb";
          VDB_CACHE = "/tmp/vdb-cache";
        };
        endpoints = {
          api = {
            port = app.parameters.port;
          };
        };
        healthcheck = {
          enable = true;
          test = [
            "${lib.getExe pkgs.curl}"
            "-fs"
            "http://localhost:${toString app.parameters.port}/"
          ];
          packages = [ pkgs.curl ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "10s";
          retries = 10;
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.dep-scan = {
            packages = with pkgs; [
              dep-scan
              cdxgen
              coreutils
              bash
            ];
          };
        };

        nixos = {
          enable = true;
          packages = with pkgs; [
            dep-scan
            cdxgen
          ];
        };
      };
    };

    test = {
      programs.script = ''
        export HOME=$(mktemp -d)
        depscan --help | grep -q "depscan"
        depscan --version | grep -q "depscan"
      '';
      services = {
        packages = [ pkgs.curl ];
        script = ''
          curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"
          $curl -fs "http://localhost:${toString app.parameters.port}/" | grep -q "{}"
        '';
      };
    };
  };
}
