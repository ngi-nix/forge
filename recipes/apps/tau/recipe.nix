{
  config,
  forge-lib,
  lib,
  pkgs,
  ...
}:

let
  app = config.apps.tau;
in
{
  apps.tau = {
    displayName = "Tau";
    description = "Web radio streaming system.";
    categories = with forge-lib.categories; [ Network ];

    usage = ''
      This app provides both the _tau-tower_ server and the _tau-radio_ client.

      #### Tau Tower
      Service for broadcasting audio to clients.

      #### Tau Radio
      Client CLI for capturing audio from your device and streaming it to _tau-tower_.

      Usage:

      ```
      tau-radio --username <user> --password <pass> --ip <server-ip> --port <server-port>
      ```

    '';

    links = {
      source = "https://github.com/tau-org";
    };

    ngi.grants = {
      Core = [
        "Tau"
      ];
    };

    parameters = {
      sourcePort = {
        value = 3001;
        description = "Port of Tau Tower, to which Tau Radio streams the audio.";
      };
      broadcastPort = {
        value = 3002;
        description = "Port of Tau Tower, from which the clients listen to the stream.";
      };
    };

    programs = {
      packages = [
        pkgs.tau-radio
      ];
      runtimes.shell.enable = true;
    };

    services = {
      components.tau-tower = {
        process.command = pkgs.tau-tower;
        process.configData."tau/tower.toml" = {
          source = pkgs.replaceVars ./config.toml {
            inherit (app.parameters) sourcePort broadcastPort;
          };
          path = "tau/tower.toml";
        };
        endpoints = {
          source = {
            port = app.parameters.sourcePort;
            appProtocol = "websocket";
          };
          broadcast = {
            port = app.parameters.broadcastPort;
          };
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.tau-tower.packages = [
            pkgs.tau-tower
          ];
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.tau-tower
          ];
        };
      };
    };

    test.services.script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

      $curl localhost:${toString app.parameters.broadcastPort} | grep "Audio Stream"
    '';
  };
}
