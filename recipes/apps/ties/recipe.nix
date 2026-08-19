{
  lib,
  config,
  pkgs,
  ...
}:
let
  recipe = config.apps.ties;
  listenPort = "8080";
in
{
  apps.ties = {
    displayName = "Ties";
    description = "A federated network to bookmark, organize, share and discover good web pages.";
    usage = ''
      For more information, see the [Ties documentation](${recipe.links.docs}).
    '';

    links = {
      website = "https://demo.ties.pub";
      source = "https://github.com/raffomania/ties";
      docs = "https://github.com/raffomania/ties/blob/main/doc/index.md";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Ties"
      ];
    };

    programs = {
      mainPackage = pkgs.ties;
      packages = [ pkgs.ties ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    services = {
      components.ties = {
        process = {
          configData."adminUsername" = {
            text = "admin";
            path = "adminUsername";
          };
          configData."adminPasswordFile" = {
            text = "/var/lib/ties/admin-password";
            path = "adminPasswordFile";
          };

          command = pkgs.writeShellScriptBin "ties" ''
            export ADMIN_USERNAME=$(<"$XDG_CONFIG_HOME/adminUsername")
            export ADMIN_PASSWORD="Admin@1234"

            ADMIN_PASS_FILE=$(<"$XDG_CONFIG_HOME/adminPasswordFile")
            if [ -s "$ADMIN_PASS_FILE" ]; then
              export ADMIN_PASSWORD=$(<"$ADMIN_PASS_FILE")
            fi

            exec ${lib.getExe pkgs.ties} "$@"
          '';

          ports = [ "${listenPort}:${listenPort}" ];
          argv = [
            "start"
            "--database-url"
            "postgresql://postgres@database/postgres"
            "--base-url"
            "http://localhost:${listenPort}"
            "--listen"
            "0.0.0.0:${listenPort}" # accept connections from outside the container
          ];
        };

        resources.database.nixosConfig = {
          services.postgresql.enable = true;
        };
      };

      runtimes.container = {
        enable = true;
        resources.database.nixosConfig = {
          services.postgresql.enableTCPIP = true;
          services.postgresql.authentication = ''
            host all all 0.0.0.0/0 trust
            host all all ::0/0 trust
          '';
        };
      };

      runtimes.nixos = {
        enable = true;
        nixosConfig = {
          services.postgresql.authentication = ''
            local all all trust
            host all all 127.0.0.1/32 trust
            host all all ::1/128 trust
          '';
        };
      };
    };

    test.services.script = ''
      # wait for ties to become ready
      for i in $(seq 1 10); do
        if curl -fs "http://localhost:${listenPort}"; then
          exit 0
        fi
        sleep 3
      done
      echo "Ties did not become ready in time"
      exit 1
    '';

  };
}
