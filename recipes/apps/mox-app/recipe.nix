{
  pkgs,
  lib,
  apps,
  ...
}:

{
  apps.mox = {
    displayName = "Mox";
    description = "Modern full-featured open source secure mail server for low-maintenance self-hosted email.";
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

      * Admin web interface: [http://localhost:8080](http://localhost:8080)
      * Account web interface: [http://localhost:8081](http://localhost:8081)
      * Webmail interface: [http://localhost:8082](http://localhost:8082)

    '';

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

    services = {
      components.mox = {
        configData."mox.conf" = {
          source = ./mox.conf;
          path = "mox.conf";
        };
        configData."domains.conf" = {
          source = ./domains.conf;
          path = "domains.conf";
        };
        preStart = ''
          echo "Installing configuration files ..."
          cp -v ''$XDG_CONFIG_HOME/mox.conf /var/lib/mox/config/mox.conf
          cp -v ''$XDG_CONFIG_HOME/domains.conf /var/lib/mox/config/domains.conf
        '';
        user = "root";
        command = pkgs.mox;
        argv = [
          "-config"
          "/var/lib/mox/config/mox.conf"
          "serve"
        ];
        ports = [
          "8080:8080"
          "8081:8081"
          "8082:8082"
        ];
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
              pkgs.coreutils # required for mkdir, echo
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

    test.script = ''
      curl="curl --retry 20 --retry-max-time 120 --retry-all-errors"

      $curl --location localhost:8080 | grep "Mox Account"
      $curl --location localhost:8081/admin | grep "Mox Admin"
      $curl --location localhost:8082/webmail | grep "Mox Webmail"
    '';
  };
}
