{
  forge-lib,
  lib,
  config,
  pkgs,
  ...
}:
let
  app = config.apps.dokieli;
in
{
  pkgs.dokieli = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.dokieli;
    };
  };

  apps.dokieli = {
    displayName = "Dokieli";
    description = "Clientside editor for decentralised article publishing, annotations, and social interactions.";
    categories = with forge-lib.categories; [ Publishing ];
    usage = ''
      dokieli is a clientside editor for authoring, annotating, and sharing
      articles in a decentralised way.

      Web interface: [${app.services.components.web.endpoints.web.forwardedUrl}](${app.services.components.web.endpoints.web.forwardedUrl})

      Open any HTML document in the interface to start authoring, or open an
      existing dokieli document to annotate or edit it directly in the browser.
    '';

    links = {
      website = "https://dokie.li";
      source = "https://github.com/dokieli/dokieli";
      docs = "https://github.com/dokieli/dokieli/wiki";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Dokieli-Collaborative"
      ];
      Entrust = [
        "Dokieli"
      ];
    };

    parameters = {
      port = {
        value = 3000;
        description = "Port of the dokieli web interface.";
      };
    };

    services = {
      components.web = {
        process = {
          command = pkgs.dokieli;
          argv = [
            "-l"
            "tcp://0.0.0.0:${toString app.parameters.port}"
          ];
        };
        endpoints = {
          web = {
            port = app.parameters.port;
          };
        };
      };
      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test.services.script = ''
      curl_retry localhost:${toString app.parameters.port} | grep "dokieli" > /dev/null
    '';

  };
}
