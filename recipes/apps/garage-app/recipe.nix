{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "garage-app";
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
}
