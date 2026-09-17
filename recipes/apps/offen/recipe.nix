{
  config,
  pkgs,
  ...
}:

let
  app = config.apps.offen;
in
{
  apps.offen = {
    displayName = "Offen";
    description = "Fair and privacy-focused web analytics.";
    longDescription = ''
      Offen is a self-hosted web analytics server that gives operators insight
      into usage while allowing users to access, review, and delete their own
      data.
    '';
    usage = ''
      First, launch the app [in a container](app/${app.name}#run-container) or
      [in a NixOS VM](app/${app.name}#run-nixos).

      #### Initial Setup

      1. Enter the running container

      ```bash
      podman exec -it offen_offen_1 bash
      ```

      or log in to the NixOS VM (the console logs in automatically as root).

      2. Create an operator account

      ```bash
      export OFFEN_DATABASE_CONNECTIONSTRING="/var/lib/offen/offen.db"
      offen setup -name <account-name> -email <email> -password <password>
      ```

      #### Web Interface

      Open the [web interface](http://localhost:3000) and log in as
      the operator using the account created in the previous step.

      Read the [docs](${app.links.docs}) for more details.
    '';

    links = {
      website = "https://www.offen.dev";
      docs = "https://docs.offen.dev";
      source = "https://github.com/offen/offen";
    };

    ngi.grants = {
      Review = [
        "offen"
        "OffenOne"
      ];
    };

    icon = ./icon.svg;

    services = {
      components.offen = {
        process.command = pkgs.offen;
        process.argv = [ "serve" ];
        process.environment = {
          OFFEN_SERVER_PORT = "3000";
          OFFEN_DATABASE_DIALECT = "sqlite3";
          OFFEN_DATABASE_CONNECTIONSTRING = "/var/lib/offen/offen.db";
        };
        process.ports = [ "3000:3000" ];
      };

      runtimes = {
        container = {
          enable = true;
          components.offen = {
            packages = [
              pkgs.bash # required for entering the container
              pkgs.coreutils # required for mkdir
              pkgs.offen # required for admin tasks
            ];
          };
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.offen # required for admin tasks
          ];
        };
      };
    };

    test.services.script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

      export OFFEN_DATABASE_CONNECTIONSTRING="/var/lib/offen/offen.db"
      offen setup -name test -email test@localhost -password test123456
      $curl localhost:3000 | grep "Offen Fair Web Analytics"
    '';
  };
}
