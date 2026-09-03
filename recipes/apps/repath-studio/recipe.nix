{
  pkgs,
  ...
}:

{
  pkgs.repath-studio = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.repath-studio.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # TODO remove when https://github.com/NixOS/nixpkgs/pull/558384 is in nixos-unstable
          ./fix-karma-sandbox.patch
        ];
      });
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
      [http://localhost:8080](http://localhost:8080) and [http://localhost:8080/schema-explorer](http://localhost:8080/schema-explorer).
    '';

    icon = ./icon.svg;

    links = {
      website = "https://repath.studio/";
      source = "https://github.com/repath-studio/repath-studio";
      docs = "https://repath.studio/get-started/interactive-shell/";
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
        $curl localhost:8080 | grep -qi "Repath Studio"
        $curl localhost:8080/schema-explorer/ | grep -qi "Schema Graph"
      '';
    };
  };
}
