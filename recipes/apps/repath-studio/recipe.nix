{
  forge-lib,
  lib,
  config,
  pkgs,
  ...
}:
let
  app = config.apps.repath-studio;
in
{
  pkgs.repath-studio = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.repath-studio;
    };
  };

  apps.repath-studio = {
    displayName = "Repath Studio";
    description = "SVG editor written in Clojurescript.";
    categories = with forge-lib.categories; [
      Development
      VectorGraphics
    ];
    usage = ''
      Repath Studio is a cross platform vector graphics editor, that combines procedural tooling with traditional design workflows.

      It includes an interactive shell, which allows evaluating code to generate shapes, or even extend the editor on the fly.

      #### Web Application & Schema Explorer

      The _repath-studio-web_ service serves the browser-based web application and schema explorer at
      [http://localhost:${toString app.services.components.repath-studio-web.endpoints.web.forwardedPort}](http://localhost:${toString app.services.components.repath-studio-web.endpoints.web.forwardedPort}) and [http://localhost:${toString app.services.components.repath-studio-web.endpoints.web.forwardedPort}/schema-explorer](http://localhost:${toString app.services.components.repath-studio-web.endpoints.web.forwardedPort}/schema-explorer).
    '';

    icon = ./icon.svg;

    links = {
      website = "https://repath.studio";
      source = "https://github.com/repath-studio/repath-studio";
      docs = "https://repath.studio/get-started/interactive-shell";
    };

    ngi.grants = {
      Commons = [ "RepathStudio" ];
    };

    programs = {
      mainPackage = pkgs.repath-studio;
      runtimes.program.enable = true;
    };

    parameters = {
      port = {
        value = 8080;
        description = "Port of the Repath Studio web interface.";
      };
    };

    services = {
      components.repath-studio-web = {
        process.environment = {
          REPATH_STUDIO_WEB_ROOT = "${pkgs.repath-studio-web}/share/repath-studio-web";
        };
        process.configData."Caddyfile" = {
          source = pkgs.replaceVars ./Caddyfile { inherit (app.parameters) port; };
          path = "Caddyfile";
        };
        process.command = pkgs.caddy;
        process.argv = [
          "run"
          "--adapter"
          "caddyfile"
          "--config"
          "$XDG_CONFIG_HOME/Caddyfile"
        ];
        endpoints = {
          web = {
            port = app.parameters.port;
          };
        };
      };

      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test = {
      services.script = ''
        curl="curl --retry 10 --retry-max-time 60 --retry-all-errors"
        $curl localhost:${toString app.parameters.port} | grep -i "Repath Studio" > /dev/null
        $curl localhost:${toString app.parameters.port}/schema-explorer/ | grep -i "Schema Explorer" > /dev/null
      '';
    };
  };
}
