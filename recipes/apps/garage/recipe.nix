{
  config,
  forge-lib,
  lib,
  pkgs,
  ...
}:

let
  app = config.apps.garage;
  configFile = pkgs.replaceVars ./garage.toml {
    inherit (app.parameters) rpcPort s3ApiPort adminApiPort;
  };
in
{
  pkgs.garage = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.garage_2;
    };
  };
  apps.garage = {
    displayName = "Garage";
    description = "Lightweight geo-distributed data store compatible with Amazon S3.";
    categories = with forge-lib.categories; [ Development ];
    usage = ''
      Garage is a self-hostable S3-compatible object storage service designed for
      geo-distributed clusters on commodity hardware.

      #### Configuration

      Garage reads its configuration from `/etc/garage.toml` by default.
      Use the `-c` flag to specify a different path:

      ```
      garage -c /path/to/garage.toml status
      ```

      #### Example

      Check cluster node status

      ```
      garage status
      ```

      Create a storage bucket

      ```
      garage bucket create my-bucket
      ```

      List all buckets

      ```
      garage bucket list
      ```

      Create an API access key

      ```
      garage key create my-app-key
      ```

      Grant a key read and write access to a bucket

      ```
      garage bucket allow --read --write --owner my-bucket --key my-app-key
      ```
    '';

    links = {
      website = "https://garagehq.deuxfleurs.fr";
      docs = "https://garagehq.deuxfleurs.fr/documentation/quick-start/";
      source = "https://git.deuxfleurs.fr/Deuxfleurs/garage";
    };

    ngi.grants = {
      Entrust = [
        "Garage"
      ];
      Commons = [
        "Garage-AdminUI"
        "Garage-Performance"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.garage
      ];

      runtimes.shell.enable = true;
    };

    parameters = {
      rpcPort = {
        value = 3900;
        description = "Port of the Garage RPC, for the nodes of the cluster.";
      };
      s3ApiPort = {
        value = 3901;
        description = "Port of the Garage S3 API.";
      };
      adminApiPort = {
        value = 3902;
        description = "Port of the Garage admin API.";
      };
    };

    services = {
      components.garage = {
        process.preStart = ''
          mkdir -p /var/lib/garage/meta /var/lib/garage/data
        '';
        process.command = pkgs.garage;
        process.argv = [
          "-c"
          "${configFile}"
          "server"
        ];
        endpoints = {
          rpc = {
            port = app.parameters.rpcPort;
            appProtocol = "garage-rpc";
          };
          s3-api = {
            port = app.parameters.s3ApiPort;
          };
          admin-api = {
            port = app.parameters.adminApiPort;
          };
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.garage.packages = [
            pkgs.bash
            pkgs.coreutils
            pkgs.garage
          ];
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.garage
          ];
        };
      };
    };

    test.services.script = ''
      curl -s -f --retry 10 --retry-max-time 120 --retry-all-errors http://localhost:${toString app.parameters.adminApiPort}/metrics > /dev/null

      if command -v podman >/dev/null 2>&1; then
        EXEC="podman exec garage_garage_1"
      else
        EXEC=""
      fi

      node_id=$($EXEC garage -c ${configFile} status | awk '/^[0-9a-f]{16}/ {print $1}')
      $EXEC garage -c ${configFile} layout assign -z dc1 -c 1G "$node_id"
      $EXEC garage -c ${configFile} layout apply --version 1

      $EXEC garage -c ${configFile} bucket create test-bucket
      $EXEC garage -c ${configFile} bucket list | grep test-bucket
    '';
  };
}
