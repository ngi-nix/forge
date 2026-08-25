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
      **BeaconDB** is an open-source, privacy-focused alternative to Google Location Services written in Rust.

      Instead of relying purely on slow GPS satellites, it allows devices to find their location by scanning nearby Wi-Fi networks and cell towers.

      This database is built by crowdsourcing: users walk around with an app which scans and maps the coordinates of nearby Wi-Fi and cell signals, uploads them to the server, and beacondb processes them into a map.

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

      #### Data collection

      ${recipe.links.website} reccomends NeoStumbler, Tower Collector, Network Survey android apps to gather data which can be uploaded to beacondb.

      Point the clients to the nginx proxy server running on port **8190**:
      - **Base URL:** `http://<your-ip>:8190`
      - **Geosubmit Path:** `/v2/geosubmit`
      - **Geolocate Path:** `/v1/geolocate`

      > [!NOTE]
      > You must physically move around while scanning, preferably get a good GPS signal so go outside, or the collected data will be discarded by BeaconDB.*

      #### Processing Data

      Data uploaded to `beacondb` is placed in a queue and must be processed before it can be used for geolocation.

      If you are running the command **inside the container or VM**, you can use the exact same config file the service uses (it is baked into the Nix store):
      ```bash
      beacondb -c ${recipe.data.config.path} process
      ```

      If you are running the command **from your host machine**, the database is exposed on `localhost:5432`, so you can use the dedicated CLI config:
      ```bash
      beacondb -c ${recipe.data.config-cli.path} process
      ```

      Once you submit the reports, you can geolocate a device which lacks GPS based on the wifi and cellular access points nearby or based on the ip address.

      #### IP Fallback

      IP fallback is integrated natively using `services.geoipupdate`.

      To enable it, simply edit `recipe.nix` and provide your free MaxMind credentials in the `resources.geoipupdate` block:

      ```nix
      AccountID = 123456; # Replace with your ID
      LicenseKey = "/path/to/your/license_key_file"; # Replace with the path to your key, eg. provided via sops or agenix secrets
      ```

      Once provided, the `geoipupdate` resource will automatically keep the `GeoLite2-City.mmdb` database updated, and `beacondb` will securely mount and read it using our `sharedState` feature!
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
      config-cli = ./config-cli.toml;
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
              source = recipe.data.config.path;
              path = "config.toml";
            };
          };
          sharedState = {
            "geoipupdate" = "/var/lib/geoip";
          };
          ports = [ "8080:8080" ];
        };

        resources.database.ports = [ "5432:5432" ];
        resources.database.nixosConfig = {
          services.postgresql.enable = true;
        };

        resources.geoipupdate = {
          role = "backend";
          nixosConfig = {
            services.geoipupdate = {
              enable = true;
              settings = {
                AccountID = 0;
                LicenseKey = "/var/lib/secrets/geoip_license";
                EditionIDs = [ "GeoLite2-City" ];
              };
            };
          };
        };

        resources.proxy = {
          role = "frontend";
          ports = [ "8190:8190" ];
          nixosConfig = {
            services.nginx = {
              enable = true;
              virtualHosts."localhost" = {
                listen = [
                  {
                    addr = "0.0.0.0";
                    port = 8190;
                  }
                ];
                locations."/" = {
                  proxyPass = "http://beacondb:8080";
                  extraConfig = "proxy_set_header X-Forwarded-For $remote_addr;";
                };
              };
            };
          };
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
        packages = [ pkgs.beacondb ];
        nixosConfig = {
          services.postgresql.enableTCPIP = true;
          services.postgresql.authentication = ''
            local all all trust
            host all all 127.0.0.1/32 trust
            host all all ::1/128 trust
            host all all 0.0.0.0/0 trust
          '';
        };
      };
    };

  };
}
