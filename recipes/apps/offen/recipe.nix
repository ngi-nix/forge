{
  config,
  forge-lib,
  lib,
  pkgs,
  ...
}:

let
  app = config.apps.offen;
in
{
  apps.offen = {
    displayName = "Offen";
    description = "Fair and privacy-focused web analytics.";
    categories = with forge-lib.categories; [ Analytics ];
    longDescription = ''
      Offen is a self-hosted web analytics server that gives operators insight
      into usage while allowing users to access, review, and delete their own
      data.
    '';
    usage = ''
      First, launch the app [in a container](app/${app.name}#run-container) or
      [in a NixOS VM](app/${app.name}#run-nixos).

      #### Web Interface

      Open the [web interface](http://localhost:${toString app.services.components.offen.endpoints.web.forwardedPort}) and log in as
      the default operator, created on the first start:

      - Email: `${app.parameters.operatorEmail}`
      - Password: `${app.services.components.offen.secrets.operator-password.value}`
    '';

    links = {
      website = "https://www.offen.dev";
      docs = "https://docs.offen.dev";
      source = "https://github.com/offen/offen";
    };

    ngi.grants = {
      Review = [
        "offen"
        "OffenOne"
      ];
    };

    icon = ./icon.svg;

    parameters = {
      port = {
        value = 3000;
        description = "Port of the Offen web interface.";
      };
      operatorAccount = {
        value = "Offen";
        description = "Name of the default operator account, created on the first start.";
      };
      operatorEmail = {
        value = "admin@localhost";
        description = "Email address of the default operator, used for login.";
      };
    };

    services = {
      components.offen = {
        process.command = pkgs.offen;
        process.argv = [ "serve" ];
        process.packages = [
          pkgs.coreutils
          pkgs.offen
        ];
        # Create the default operator account on the first start
        # (`offen setup` refuses to overwrite existing data).
        process.preStart = ''
          if [ ! -e "$OFFEN_DATABASE_CONNECTIONSTRING" ]; then
            offen setup \
              -name ${lib.escapeShellArg app.parameters.operatorAccount} \
              -email ${lib.escapeShellArg app.parameters.operatorEmail} \
              -password "$(< "$CREDENTIALS_DIRECTORY"/operator-password)"
          fi
        '';
        process.environment = {
          OFFEN_SERVER_PORT = app.parameters.port;
          OFFEN_DATABASE_DIALECT = "sqlite3";
          OFFEN_DATABASE_CONNECTIONSTRING = "/var/lib/offen/offen.db";
        };

        secrets.secret = {
          value = "aW5zZWN1cmUtZGVmYXVsdA=="; # "insecure-default"
          description = "Base64 encoded secret for signing login cookies.";
          environment = "OFFEN_SECRET";
        };

        secrets.operator-password = {
          value = "default-password";
          description = "Password of the default operator (at least 8 characters).";
        };

        healthcheck = {
          enable = true;
          test = [
            "curl"
            "-fs"
            "http://offen:${toString app.parameters.port}/healthz"
          ];
          packages = [ pkgs.curl ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "10s";
          retries = 10;
        };

        endpoints = {
          web = {
            port = app.parameters.port;
          };
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.offen = {
            packages = [
              pkgs.bash # required for entering the container
              pkgs.coreutils # required for mkdir
              pkgs.offen # required for admin tasks
            ];
          };
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.offen # required for admin tasks
          ];
        };
      };
    };

    test.services = {
      packages = [ pkgs.curl ];
      script = ''
        curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

        $curl localhost:${toString app.parameters.port} | grep "Offen Fair Web Analytics"

        # Log in as the default operator
        $curl --fail --request POST localhost:${toString app.parameters.port}/api/login \
          --header "Content-Type: application/json" \
          --data ${
            lib.escapeShellArg (
              builtins.toJSON {
                username = app.parameters.operatorEmail;
                password = app.services.components.offen.secrets.operator-password.value;
              }
            )
          }
      '';
    };
  };
}
