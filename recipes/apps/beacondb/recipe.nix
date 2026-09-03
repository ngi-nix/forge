{
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.beacondb;
in
{
  apps.beacondb = {
    displayName = "BeaconDB";
    description = "A privacy focused assisted GPS service written in Rust.";
    usage = ''
      This is a privacy focused assisted GPS service written in Rust.

      #### Getting Started
      beacondb requires a PostgreSQL database. There are several ways to run the server:
        - **Container:** Run beacondb together with a PostgreSQL service using the container runtime.
        - **NixOS/VM:** Run beacondb as a NixOS service with PostgreSQL configured by the VM runtime.
        - **Local binary:** Use the beacondb binary directly with an existing PostgreSQL instance.

      For instructions on starting each runtime, click the `Run` button in the top-right corner of this page.

      If you already have PostgreSQL running locally, you can start beacondb directly with:

      ```bash
      beacondb -c ${recipe.data.config.name} serve
      ```

      Example config.toml:

      ```
      ${recipe.data.config}
      ```
    '';

    links = {
      website = "https://beacondb.net";
      source = "https://github.com/beacondb/beacondb";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "BeaconDB"
      ];
    };

    data = {
      config = ./config.toml;
    };

    programs = {
      mainPackage = pkgs.beacondb;
      packages = [ pkgs.beacondb ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    services = {
      components.beacondb = {
        process = {
          command = pkgs.beacondb;
          argv = [
            "-c"
            "$XDG_CONFIG_HOME/config.toml"
            "serve"
          ];
          configData = {
            "config.toml" = {
              source = ./config.toml;
              path = "config.toml";
            };
          };
        };

        resources.database.nixosConfig = {
          services.postgresql.enable = true;
        };
      };

      runtimes.container = {
        enable = true;
        resources.database.nixosConfig = {
          services.postgresql.enableTCPIP = true;
          services.postgresql.authentication = ''
            host all all 0.0.0.0/0 trust
            host all all ::0/0 trust
          '';
        };
      };

      runtimes.nixos = {
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
}
