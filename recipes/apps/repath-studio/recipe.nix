{
  forge-lib,
  lib,
  pkgs,
  ...
}:

{
  pkgs.repath-studio = {
    build.builders.identity = {
      enable = true;
      # TODO remove once https://github.com/NixOS/nixpkgs/pull/578613 is available
      derivation = pkgs.callPackage ../../_nixpkgs/repath-studio/package.nix { };
    };
  };

  apps.repath-studio = {
    displayName = "Repath Studio";
    description = "SVG editor written in Clojurescript.";
    categories = with forge-lib.categories; [
      Development
      VectorGraphics
    ];
    screenshots = [
      {
        url = "https://raw.githubusercontent.com/repath-studio/website/8126927cbb817cef29003d8b9ec4f504535f6688/docs/assets/images/studio.png";
        hash = "sha256-+V16PVN5O6EYXYXEYgl5dQVUC2LkdKEa8pgl8HAeW0Q=";
        caption = "Studio";
      }
      {
        url = "https://raw.githubusercontent.com/repath-studio/website/8126927cbb817cef29003d8b9ec4f504535f6688/docs/assets/images/history.png";
        hash = "sha256-1j3ug82r5AVQGwxojD3c+PQzayxGoua+BuQpF2TNuno=";
        caption = "History";
      }
      {
        url = "https://raw.githubusercontent.com/repath-studio/website/8126927cbb817cef29003d8b9ec4f504535f6688/docs/assets/images/repl.png";
        hash = "sha256-Odsz+b9FmtA3MIGMLCCj03ZZ25KdoHcAdO4WZ22q9S0=";
        caption = "Repl";
      }
      {
        url = "https://raw.githubusercontent.com/repath-studio/website/8126927cbb817cef29003d8b9ec4f504535f6688/docs/assets/images/animations.png";
        hash = "sha256-U2n+3FAT8FkchKaXZuMxrCrulmTP37SKxmHnHT82mNg=";
        caption = "Animations";
      }
    ];
    usage = ''
      Repath Studio is a cross platform vector graphics editor, that combines procedural tooling with traditional design workflows.

      It includes an interactive shell, which allows evaluating code to generate shapes, or even extend the editor on the fly.

      #### Web Application & Schema Explorer

      The _repath-studio-web_ service serves the browser-based web application and schema explorer at
      [http://localhost:8080](http://localhost:8080) and [http://localhost:8080/schema-explorer](http://localhost:8080/schema-explorer).
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
        process.ports = [ "8080:8080" ];
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
