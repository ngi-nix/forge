{
  lib,
  pkgs,
  ...
}:
{
  pkgs.dokieli = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.dokieli;
    };
  };

  apps.dokieli = {
    displayName = "Dokieli";
    description = "Clientside editor for decentralised article publishing, annotations, and social interactions.";
    categories = with lib.categories; [ Development ];
    usage = ''
      dokieli is a clientside editor for authoring, annotating, and sharing
      articles in a decentralised way.

      Web interface: [http://localhost:3000](http://localhost:3000)

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

    services = {
      components.web = {
        process = {
          command = pkgs.dokieli;
          argv = [
            "-l"
            "tcp://0.0.0.0:3000"
          ];
          ports = [ "3000:3000" ];
        };
      };
      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test.services.script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"
      $curl localhost:3000 | grep -q "dokieli"
    '';

  };
}
