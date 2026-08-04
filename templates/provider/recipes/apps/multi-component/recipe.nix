{
  config,
  pkgs,
  ...
}:

let
  recipe = config.apps.multi-component;
in
{
  apps.multi-component = {
    displayName = "Advanced Example";
    description = "Advanced multi-component configuration.";
    usage = ''
      This application demonstrates the _hello-web_ package running across all
      Forge runtimes.

      ## Program

      Run _hello-web_ CLI in a _program_ or _shell_ runtime.

      CLI returns a default greeting:

      ```bash
      $ hello-web
      ```

      ```bash
      Hello, world!
      ```

      ## Service

      Run _hello-web_ and _PostgREST API_ as web service with _PostgreSQL_
      database and _Nginx _reverse proxy in a _container_ or _nixos_ runtime.

      ```
      ┌─────────────────────────────────────┐
      │ Resource: reverse-proxy (nginx:8000)│
      └──────────────┬──────────────────────┘
                     │
             ┌───────┴────────┐
             ▼                ▼
      ┌─────────────┐  ┌─────────────┐
      │  Component  │  │  Component  │
      │  web (:5000)│  │  api (:5001)│
      └──────┬──────┘  └──────┬──────┘
             │                │
             └───────┬────────┘
                     ▼
      ┌─────────────────────────────────────┐
      │   Resource: database (postgres)     │
      └─────────────────────────────────────┘
      ```

      ### Web service

      The web service returns a random greeting in one of several languages:

      ```bash
      curl localhost:8000/
      ```

      ```bash
      Bonjour, monde!
      ```

      ### API

      The API service allows to read and write to the greetings database:

      -  List all greetings

      ```bash
      curl localhost:8000/api/greetings
      ```

      - Filter greetings by language

      ```bash
      curl "localhost:8000/api/greetings?language=eq.English"
      ```

      - Add a new greeting

      ```bash
      curl -X POST \
        --header "Content-Type: application/json" \
        --data '{"language":"Japanese","message":"こんにちは、世界！"}' \
        localhost:8000/api/greetings
      ```
    '';

    links = {
      website = "https://github.com/ngi-nix/forge";
    };

    ngi.grants = {
      Commons = [
        "Example 1"
        "Example 2"
      ];
      Core = [
        "Example 1"
        "Example 2"
      ];
    };

    programs = {
      packages = [ pkgs.hello-web ];
      mainPackage = pkgs.hello-web;

      runtimes = {
        program.enable = true;
        shell.enable = true;
      };
    };

    services = {
      # Main web component
      components.web = {
        process = {
          command = pkgs.hello-web;
          argv = [ "serve" ];
          preStart = ''
            until pg_isready -h database -U postgres; do
              sleep 1
            done
            hello-web initdb
          '';
          packages = with pkgs; [
            coreutils
            hello-web
            postgresql
          ];
          environment = {
            DB_ENABLE = "true";
            DB_HOST = "database";
            DB_NAME = "postgres";
            DB_USER = "postgres";
          };
        };
        healthcheck = {
          enable = true;
          test = [
            "curl"
            "-fs"
            "http://localhost:5000/health"
          ];
          packages = [ pkgs.curl ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "1s";
          retries = 10;
        };

        # DB resource (shared with api component)
        resources.database.nixosConfig = {
          services.postgresql.enable = true;
        };

        # Reverse proxy resource (shared with api component)
        resources.reverse-proxy = {
          nixosConfig = {
            services.nginx = {
              enable = true;
              virtualHosts."_" = {
                listen = [
                  {
                    addr = "0.0.0.0";
                    port = 8000;
                  }
                ];
                locations."/" = {
                  proxyPass = "http://web:5000";
                };
              };
            };
          };
          ports = [ "8000:8000" ];
          role = "frontend";
        };
      };

      # PostgREST API component
      components.api = {
        process = {
          configData."postgrest.conf" = {
            text = ''
              db-uri = "postgresql://postgres@database/postgres"
              db-schemas = "public"
              db-anon-role = "postgres"
              server-host = "0.0.0.0"
              server-port = 5001
            '';
            path = "postgrest.conf";
          };
          command = pkgs.postgrest;
          argv = [ "$XDG_CONFIG_HOME/postgrest.conf" ];
          packages = with pkgs; [
            coreutils
            postgresql
          ];
        };
        healthcheck = {
          enable = true;
          test = [
            "curl"
            "-fs"
            "http://localhost:5001/"
          ];
          packages = [ pkgs.curl ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "1s";
          retries = 10;
        };

        # DB resource (shared with web component)
        resources.database = recipe.services.components.web.resources.database;

        # Reverse proxy resource (shared with web component)
        resources.reverse-proxy = {
          nixosConfig = {
            services.nginx = {
              enable = true;
              virtualHosts."_".locations."/api/" = {
                proxyPass = "http://api:5001/";
              };
            };
          };
          ports = recipe.services.components.web.resources.reverse-proxy.ports;
          role = recipe.services.components.web.resources.reverse-proxy.role;
        };

        # Wait for `web` which runs `initdb` to create the `greetings` table.
        dependsOn = [ "web" ];
      };

      # Runtimes
      runtimes = {
        container = {
          enable = true;
          resources.database.nixosConfig = {
            services.postgresql.enableTCPIP = true;
            services.postgresql.authentication = ''
              host all all 0.0.0.0/0 trust
              host all all ::0/0 trust
            '';
          };
        };

        nixos = {
          enable = true;
          nixosConfig = {
            services.postgresql.authentication = ''
              local all all trust
              host all all 127.0.0.1/32 trust
              host all all ::1/128 trust
            '';
          };
        };
      };
    };

    test.services = {
      script = ''
        curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"
        $curl localhost:8000/health | grep "OK"
        $curl "localhost:8000/api/greetings?id=eq.1" | grep "Hello, world!"
      '';
    };
  };
}
