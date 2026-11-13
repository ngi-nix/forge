{
  config,
  forge-lib,
  lib,
  pkgs,
  ...
}:

let
  app = config.apps.rotonda;
in
{
  pkgs.rotonda = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.rotonda;
    };
  };
  apps.rotonda = {
    displayName = "Rotonda";
    description = "Composable and programmable BGP routing engine.";
    categories = with forge-lib.categories; [ Network ];
    usage = ''
      Rotonda collects routing information from BGP and BMP sessions into an
      in-memory Routing Information Base (RIB), queryable via an HTTP/JSON API.

      #### HTTP API

      Query the routing information base

      ```
      curl http://localhost:${toString app.parameters.apiPort}/
      ```

      #### BMP sessions

      Rotonda listens for BMP (BGP Monitoring Protocol) connections on port ${toString app.parameters.bmpPort}.
      Point your BMP-capable router to this address to start collecting routes.

      #### BGP sessions

      Add BGP peers to `rotonda.conf` under `[units.bgp-in]` to accept BGP sessions.
    '';

    links = {
      website = "https://www.nlnetlabs.nl/projects/routing/rotonda";
      docs = "https://rotonda.docs.nlnetlabs.nl";
      source = "https://github.com/NLnetLabs/rotonda";
    };

    ngi.grants = {
      Entrust = [
        "Rotonda"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.rotonda
      ];

      runtimes.shell.enable = true;
    };

    parameters = {
      apiPort = {
        value = 8080;
        description = "Port of the Rotonda HTTP API.";
      };
      bmpPort = {
        value = 11019;
        description = "Port on which Rotonda listens for BMP connections.";
      };
    };

    services = {
      components.rotonda = {
        process.command = pkgs.rotonda;
        process.argv = [
          "-c"
          "${pkgs.replaceVars ./rotonda.conf { inherit (app.parameters) apiPort bmpPort; }}"
        ];
        endpoints = {
          api = {
            port = app.parameters.apiPort;
          };
          bmp = {
            port = app.parameters.bmpPort;
            appProtocol = "bmp";
          };
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.rotonda.packages = [
            pkgs.bash
            pkgs.coreutils
            pkgs.rotonda
          ];
        };

        nixos = {
          enable = true;
          packages = [ pkgs.rotonda ];
        };
      };
    };

    test.services = {
      packages = [
        pkgs.netcat
      ];
      script = ''
        curl -f --retry 10 --retry-max-time 120 --retry-all-errors \
          http://localhost:${toString app.parameters.apiPort}/

        nc -z localhost ${toString app.parameters.bmpPort}
      '';
    };
  };
}
