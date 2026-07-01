{
  pkgs,
  ...
}:

{
  apps.python-web = {
    displayName = "Python Web Example";
    description = "Example web API with database backend.";
    usage = ''
      This is a simple example application that provides a web API for
      managing a list of users.

      * Initialize database

      ```bash
      curl -X POST localhost:8000/init
      ```

      * Add a new user

      ```bash
      curl -X POST \
        --header "Content-Type: application/json" \
        --data '{"name":"username"}' \
      localhost:8000/users
      ```

      * Get list of all users

      ```bash
      curl localhost:8000/users
      ```

      * API

      ```bash
      curl localhost:8000/api
      ```
    '';

    links = {
      website = pkgs.python-web.meta.homepage;
      docs = pkgs.python-web.meta.homepage;
      source = pkgs.python-web.meta.homepage;
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

    services = {
      # Main app component
      components.python-web = {
        process.command = pkgs.python-web;
        process.preStart = ''
          until ${pkgs.postgresql}/bin/pg_isready -h database -U postgres; do
            sleep 1
          done
        '';
        process.packages = with pkgs; [ coreutils ];
        process.environment = {
          DB_HOST = "database";
          DB_NAME = "postgres";
          DB_USER = "postgres";
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
                  proxyPass = "http://python-web:5000";
                };
              };
            };
          };
          ports = [ "8000:8000" ];
          role = "frontend";
        };
      };

      # API component
      components.api = {
        process.command = pkgs.postgrest;
        process.configData."postgrest.conf" = {
          text = ''
            db-uri = "postgresql://postgres@database/postgres"
            db-schemas = "public"
            db-anon-role = "postgres"
            server-host = "0.0.0.0"
            server-port = 5001
          '';
          path = "postgrest.conf";
        };
        process.preStart = ''
          until ${pkgs.postgresql}/bin/pg_isready -h database -U postgres; do
            sleep 1
          done
        '';
        process.argv = [ "$XDG_CONFIG_HOME/postgrest.conf" ];
        process.packages = with pkgs; [ coreutils ];

        # DB resource (shared with main app component)
        resources.database.nixosConfig = {
          services.postgresql.enable = true;
        };

        # Reverse proxy resource (shared with main app component)
        resources.reverse-proxy = {
          nixosConfig = {
            services.nginx = {
              enable = true;
              virtualHosts."_".locations."/api/" = {
                proxyPass = "http://api:5001/";
              };
            };
          };
          ports = [ "8000:8000" ];
          role = "frontend";
        };
        after = [ "python-web" ];
      };

      runtimes = {
        # Container runtime
        container = {
          enable = true;

          # Container specific resources configuration
          resources.database.nixosConfig = {
            services.postgresql.enableTCPIP = true;
            services.postgresql.authentication = ''
              host all all 0.0.0.0/0 trust
              host all all ::0/0 trust
            '';
          };
        };

        # NixOS runtime
        nixos = {
          enable = true;

          nixosConfig = {
            # NixOS specific configuration for all components, resources and
            # whole system
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

        $curl -X POST localhost:8000/init

        $curl -X POST \
          --header "Content-Type: application/json" \
          --data '{"name":"username"}' \
          localhost:8000/users

        $curl localhost:8000/users
      '';
    };
  };
}
