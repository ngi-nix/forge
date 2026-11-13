{
  config,
  forge-lib,
  lib,
  pkgs,
  ...
}:

let
  app = config.apps.pdfding;
in
{
  pkgs.pdfding = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.pdfding;
    };
  };

  apps.pdfding = {
    displayName = "PdfDing";
    description = "Self-hosted PDF manager, viewer and editor.";
    categories = with forge-lib.categories; [ Office ];
    longDescription = ''
      PdfDing is a self-hosted PDF manager, viewer and editor offering a seamless
      user experience across multiple devices.
    '';
    usage = ''
      First, launch the app [in a container](app/${app.name}#run-container) (requires Podman) or [in a NixOS VM](app/${app.name}#run-nixos).

      ##### Initial Setup

      Create an admin account (with an email required eg. `admin@localhost`):

      - In container:

        ```bash
        podman exec -it pdfding_pdfding_1 pdfding-manage createsuperuser
        ```

      - In NixOS VM (logged in as root):

        ```bash
        pdfding-manage createsuperuser
        ```

      ##### Web Interface

      Open the [web interface](http://localhost:${toString app.services.components.pdfding.endpoints.web.forwardedPort}) and log in using the account created in the previous step.
    '';

    links = {
      website = "https://pdfding.com";
      docs = "https://docs.pdfding.com";
      source = "https://codeberg.org/mrmn/PdfDing";
    };

    ngi.grants = {
      Commons = [
        "PdfDing"
      ];
    };

    parameters = {
      port = {
        value = 8080;
        description = "Port of the PdfDing web interface.";
      };
    };

    services = {
      components.pdfding = {
        process = {
          command = pkgs.writeShellScriptBin "pdfding" ''
            mkdir -p /var/lib/pdfding/{db,media}
            ${pkgs.pdfding}/bin/pdfding-manage migrate
            ${pkgs.pdfding}/bin/pdfding-manage clean_up
            exec ${pkgs.pdfding}/bin/pdfding-start "$@"
          '';
          environment = {
            HOST_IP = "0.0.0.0";
            HOST_PORT = app.parameters.port;
            HOST_NAME = "localhost,127.0.0.1,0.0.0.0,pdfding";
            SECRET_KEY = "insecure-default-key-change-in-production";
            CSRF_COOKIE_SECURE = "FALSE";
            SESSION_COOKIE_SECURE = "FALSE";
            ACCOUNT_DEFAULT_HTTP_PROTOCOL = "http";
            DATA_DIR = "/var/lib/pdfding";
          };
          packages = [
            pkgs.coreutils
            pkgs.pdfding
          ];
        };

        endpoints = {
          web = {
            port = app.parameters.port;
          };
        };

        healthcheck = {
          enable = true;
          test = [
            "curl"
            "-fs"
            "http://localhost:${toString app.parameters.port}/accountlogin/"
          ];
          packages = [ pkgs.curl ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "10s";
          retries = 30;
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.pdfding.packages = [
            pkgs.bash
            pkgs.coreutils
            pkgs.pdfding
          ];
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.pdfding
          ];
        };
      };
    };

    test.services = {
      packages = [
        pkgs.curl
        pkgs.pdfding
      ];
      script = ''
        curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"

        $curl -fsL localhost:${toString app.parameters.port} | grep "<title>PdfDing</title>"
        $curl -fs localhost:${toString app.parameters.port}/accountlogin/ | grep "PdfDing"
      '';
    };
  };
}
