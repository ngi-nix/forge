{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "offen-app";
  displayName = "Offen";
  description = "Fair and privacy-focused web analytics.";
  usage = ''
    Offen is a self-hosted web analytics server that gives operators insight
    into usage while allowing users to access, review, and delete their own data.

    #### Access

    Open the Offen interface at `http://localhost:3000`.

    #### Initial Setup

    Create an account on first run:
    ```
    export OFFEN_DATABASE_CONNECTIONSTRING="/var/lib/offen/offen.db"
    offen setup -name <account-name> -email <email> -password <password>
    ```

    _Available in: container, nixos._
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
      preStart = ''
        mkdir --parents --verbose /var/lib/offen
      '';
      command = pkgs.mypkgs.offen;
      argv = [ "serve" ];
      environment = {
        OFFEN_SERVER_PORT = "3000";
        OFFEN_DATABASE_DIALECT = "sqlite3";
        OFFEN_DATABASE_CONNECTIONSTRING = "/var/lib/offen/offen.db";
      };
    };

    runtimes = {
      container = {
        enable = true;
        packages = [
          pkgs.bash # required for entering the container
          pkgs.coreutils # required for mkdir
          pkgs.mypkgs.offen # required for admin tasks
        ];
        composeFile = ./compose.yaml;
      };

      nixos = {
        enable = true;
        packages = [
          pkgs.mypkgs.offen # required for admin tasks
        ];
        vm.forwardPorts = [
          "3000:3000"
        ];
      };
    };
  };

  test.script = ''
    curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

    export OFFEN_DATABASE_CONNECTIONSTRING="/var/lib/offen/offen.db"
    offen setup -name test -email test@localhost -password test123456
    $curl localhost:3000 | grep "Offen Fair Web Analytics"
  '';
}
