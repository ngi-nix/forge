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
      curl -X POST localhost:5000/init
      ```

      * Add a new user

      ```bash
      curl -X POST \
        --header "Content-Type: application/json" \
        --data '{"name":"username"}' \
      localhost:5000/users
      ```

      * Get list of all users

      ```bash
      curl localhost:5000/users
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
      components = {
        python-web = {
          command = pkgs.python-web;
          ports = [ "5000:5000" ];
          environment = {
            DB_HOST = "database";
            DB_NAME = "postgres";
            DB_USER = "postgres";
          };
        };
      };

      extraComponents = {
        database = {
          nixosConfig = {
            services.postgresql.enable = true;
          };
          ports = [ "5432:5432" ];
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.python-web.packages = [ pkgs.python-web ];
          extraComponents.database.nixosConfig = {
            services.postgresql.enableTCPIP = true;
            services.postgresql.authentication = ''
              local all all trust
              host all all 0.0.0.0/0 trust
              host all all ::0/0 trust
            '';
          };
        };

        nixos = {
          enable = true;
          extraComponents.database.nixosConfig = {
            networking.extraHosts = "127.0.0.1 database";
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
        curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

        $curl -X POST localhost:5000/init

        $curl -X POST \
          --header "Content-Type: application/json" \
          --data '{"name":"username"}' \
          localhost:5000/users

        $curl localhost:5000/users
      '';
    };
  };
}
