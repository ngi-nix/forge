{
  pkgs,
  ...
}:

{
  apps.garage = {
    displayName = "Garage";
    description = "Lightweight geo-distributed data store compatible with Amazon S3.";
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
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.garage_2
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    services = {
      components.garage = {
        preStart = ''
          mkdir -p /var/lib/garage/meta /var/lib/garage/data
        '';
        command = pkgs.garage_2;
        argv = [
          "-c"
          "${./garage.toml}"
          "server"
        ];
        ports = [
          "3900:3900"
          "3901:3901"
          "3902:3902"
        ];
      };

      runtimes = {
        container = {
          enable = true;
          components.garage.packages = [
            pkgs.bash
            pkgs.coreutils
            pkgs.garage_2
          ];
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.garage_2
          ];
        };
      };
    };

    test.services.script = ''
      curl -s -f --retry 10 --retry-max-time 120 --retry-all-errors http://localhost:3902/metrics > /dev/null

      if command -v podman >/dev/null 2>&1; then
        EXEC="podman exec garage_garage_1"
      else
        EXEC=""
      fi

      node_id=$($EXEC garage -c ${./garage.toml} status | awk '/^[0-9a-f]{16}/ {print $1}')
      $EXEC garage -c ${./garage.toml} layout assign -z dc1 -c 1G "$node_id"
      $EXEC garage -c ${./garage.toml} layout apply --version 1

      $EXEC garage -c ${./garage.toml} bucket create test-bucket
      $EXEC garage -c ${./garage.toml} bucket list | grep test-bucket
    '';
  };
}
