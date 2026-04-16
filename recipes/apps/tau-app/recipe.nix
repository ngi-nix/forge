{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "tau-app";
  displayName = "Tau";
  description = "Web radio streaming system.";

  usage = ''
    This app provides both the _tau-tower_ server and the _tau-radio_ client.

    #### tau-tower
    Service for broadcasting audio to clients.

    Ports
    - Listen: 3001
    - Broadcast: 3002

    _Available in: container, nixos._

    #### tau-radio
    Client CLI for capturing audio from your device and streaming it to _tau-tower_.

    Usage:
    ```
    tau-radio --username <user> --password <pass> --ip <server-ip> --port <server-port>
    ```

    _Available in: shell._
  '';

  links = {
    source = "https://github.com/tau-org";
  };

  ngi.grants = {
      Core = [
        "Tau"
      ];
  };

  programs = {
    components.default = {
      packages = [
        pkgs.mypkgs.tau-radio
      ];
    };
    runtimes.shell = {
      enable = true;
    };
  };

  services = {
    components.tau-tower = {
      command = pkgs.mypkgs.tau-tower;
      configData."tau/tower.toml" = {
        source = ./config.toml;
        path = "tau/tower.toml";
      };
    };

    runtimes = {
      container = {
        enable = true;
        packages = [
          pkgs.mypkgs.tau-tower
        ];
        composeFile = ./compose.yaml;
      };

      nixos = {
        enable = true;
        extraConfig = {
          environment.systemPackages = [
            pkgs.mypkgs.tau-tower
          ];
        };
        vm.forwardPorts = [
          "3001:3001"
          "3002:3002"
        ];
      };
    };
  };

  test.script = ''
    curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

    $curl localhost:3002 | grep "Audio Stream"
  '';
}
