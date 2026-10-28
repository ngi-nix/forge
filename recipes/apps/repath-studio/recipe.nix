{
  config,
  pkgs,
  ...
}:
let
  app = config.apps.repath-studio;
in
{
  pkgs.repath-studio = {
    build.identityBuilder = {
      enable = true;
      # TODO remove once https://github.com/NixOS/nixpkgs/pull/578613 is available
      derivation = pkgs.callPackage ../../_nixpkgs/repath-studio/package.nix { };
    };
  };

  apps.repath-studio = {
    displayName = "Repath Studio";
    description = "SVG editor written in Clojurescript.";
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

    services = {
      components.repath-studio-web = {
        process.environment = {
          REPATH_STUDIO_WEB_ROOT = "${pkgs.repath-studio-web}/share/repath-studio-web";
        };
        process.configData."Caddyfile" = {
          source = ./Caddyfile;
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
            port = 8080;
          };
        };
      };

      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test = {
      services.script = ''
        curl="curl --retry 10 --retry-max-time 60 --retry-all-errors"
        $curl localhost:8080 | grep -i "Repath Studio" > /dev/null
        $curl localhost:8080/schema-explorer/ | grep -i "Schema Explorer" > /dev/null
      '';
    };
  };
}
