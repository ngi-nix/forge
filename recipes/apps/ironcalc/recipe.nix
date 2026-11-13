{
  forge-lib,
  lib,
  config,
  pkgs,
  ...
}:
let
  app = config.apps.ironcalc;
in
{
  pkgs.ironcalc = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.ironcalc;
    };
  };
  apps.ironcalc = {
    displayName = "IronCalc";
    description = "Open source selfhosted spreadsheet engine.";
    categories = with forge-lib.categories; [
      Office
      Development
    ];

    usage = ''
      IronCalc is an Open source spreadsheet engine and ecosystem.

      #### Access

      Ironcalc will be available on [http://localhost:${toString app.services.components.ironcalc.endpoints.web.forwardedPort}](http://localhost:${toString app.services.components.ironcalc.endpoints.web.forwardedPort}).

      You can specify a different database path with the `IRONCALC_DB_PATH` environment variable.

    '';

    icon = ./icon.svg;

    links = {
      website = "https://www.ironcalc.com";
      docs = "https://docs.ironcalc.com/";
      source = "https://github.com/ironcalc/IronCalc";
    };

    ngi.grants = {
      Core = [ "IronCalc" ];
      Commons = [
        "IronCalc-conditional"
      ];
    };

    parameters = {
      port = {
        value = 8000;
        description = "Port of the IronCalc web interface.";
      };
    };

    services = {
      components.ironcalc = {
        process.command = lib.getExe pkgs.ironcalc;
        process.environment = {
          ROCKET_ADDRESS = "0.0.0.0";
          ROCKET_PORT = app.parameters.port;
          IRONCALC_DB_PATH = "/var/lib/ironcalc/ironcalc.sqlite";
        };
        endpoints = {
          web = {
            port = app.parameters.port;
          };
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.ironcalc = {
            packages = [ pkgs.ironcalc ];
          };
        };
        nixos = {
          enable = true;
          packages = [ pkgs.ironcalc ];
        };
      };
    };

    test.services.script = ''
      curl="curl --retry 8 --retry-max-time 120 --retry-all-errors"
      $curl localhost:${toString app.parameters.port} | grep -q "IronCalc"
    '';
  };
}
