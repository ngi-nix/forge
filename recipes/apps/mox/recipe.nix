{
  config,
  pkgs,
  forge-lib,
  lib,
  apps,
  ...
}:
let
  app = config.apps.mox;
in
{
  pkgs.mox = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.mox;
    };
  };
  apps.mox = {
    displayName = "Mox";
    description = "Modern full-featured open source secure mail server for low-maintenance self-hosted email.";
    categories = with forge-lib.categories; [ Email ];
    usage = ''
      Mox is a modern, full-featured, open source secure mail server providing
      SMTP, IMAP4, webmail, SPF/DKIM/DMARC, and more.

      ##### Administration

      If running inside a container, connect to it with:

      ```bash
      podman-compose -f result/mox/compose.yaml exec mox bash
      ```

      Set admin password:

      ```bash
      echo "adminpassword" | mox -config /var/lib/mox/config/mox.conf setadminpassword
      chown mox /var/lib/mox/config/adminpasswd
      ```

      ##### URLs

      * Account web interface: [http://localhost:${toString app.services.components.mox.endpoints.account.forwardedPort}](http://localhost:${toString app.services.components.mox.endpoints.account.forwardedPort})
      * Admin web interface: [http://localhost:${toString app.services.components.mox.endpoints.admin.forwardedPort}/admin](http://localhost:${toString app.services.components.mox.endpoints.admin.forwardedPort}/admin)
      * Webmail interface: [http://localhost:${toString app.services.components.mox.endpoints.webmail.forwardedPort}/webmail](http://localhost:${toString app.services.components.mox.endpoints.webmail.forwardedPort}/webmail)

    '';
    maintainers = with lib.maintainers; [
      ngi-team
    ];

    links = {
      website = "https://www.xmox.nl/";
      docs = "https://www.xmox.nl/install/";
      source = "https://github.com/mjl-/mox";
    };

    ngi.grants = {
      Core = [
        "Mox-Automation"
      ];
      Entrust = [
        "Mox"
      ];
      Review = [
        "Mox-API"
      ];
    };

    icon = ./icon.svg;

    parameters = {
      accountPort = {
        value = 8080;
        description = "Port of the Mox account web interface.";
      };
      adminPort = {
        value = 8081;
        description = "Port of the Mox admin web interface.";
      };
      webmailPort = {
        value = 8082;
        description = "Port of the Mox webmail interface.";
      };
    };

    services = {
      components.mox = {
        process.configData."mox.conf" = {
          source = pkgs.replaceVars ./mox.conf {
            inherit (app.parameters) accountPort adminPort webmailPort;
          };
          path = "mox.conf";
        };
        process.configData."domains.conf" = {
          source = ./domains.conf;
          path = "domains.conf";
        };
        process.user = "root";
        process.command = pkgs.mox;
        process.argv = [
          "-config"
          "$XDG_CONFIG_HOME/mox.conf"
          "serve"
        ];
        endpoints = {
          account = {
            port = app.parameters.accountPort;
          };
          admin = {
            port = app.parameters.adminPort;
          };
          webmail = {
            port = app.parameters.webmailPort;
          };
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.mox = {
            setup = ''
              # Create Mox keys and data files
              if ! [ -d /var/lib/mox/config ]; then
                mkdir -p /var/lib/mox/config && cd /var/lib/mox

                # Generate DKIM keys
                mkdir -p config/dkim
                ${lib.getExe' pkgs.mox "mox"} dkim genrsa > config/dkim/dkima.rsa2048.privatekey.pkcs8.pem
                ${lib.getExe' pkgs.mox "mox"} dkim genrsa > config/dkim/dkimb.rsa2048.privatekey.pkcs8.pem

                # Create data directory
                mkdir data
                chown mox:mox data
              fi
            '';
            packages = [
              pkgs.bash # required for entering the container
              pkgs.coreutils # required by setup script
              pkgs.mox # required for admin tasks
            ];
          };
        };

        nixos = {
          enable = true;
          setup = apps.mox.services.runtimes.container.components.mox.setup;
          packages = [ pkgs.mox ];
          nixosConfig = {
            networking.enableIPv6 = false;
            # Use a public DNSSEC-validating resolver
            networking.nameservers = [ "8.8.8.8" ];
          };
        };
      };
    };

    test.services.script = ''
      curl="curl --retry 20 --retry-max-time 120 --retry-all-errors"

      $curl --location localhost:${toString app.parameters.accountPort} | grep "Mox Account"
      $curl --location localhost:${toString app.parameters.adminPort}/admin | grep "Mox Admin"
      $curl --location localhost:${toString app.parameters.webmailPort}/webmail | grep "Mox Webmail"
    '';
  };
}
