{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  displayName = "Mox";
  description = "Modern full-featured open source secure mail server for low-maintenance self-hosted email.";
  usage = ''
    Mox is a modern, full-featured, open source secure mail server providing
    SMTP, IMAP4, webmail, SPF/DKIM/DMARC, and more.

    #### Administration

    If running inside a container, connect to it with:
    ```
    podman-compose -f result/mox-app/compose.yaml exec mox-app bash
    ```

    Set admin password:
    ```
    echo "adminpassword" | mox -config /var/lib/mox/config/mox.conf setadminpassword
    chown mox /var/lib/mox/config/adminpasswd
    ```

    #### URLs

    * Admin web interface: `http://localhost:8080`
    * Account web interface: `http://localhost:8081`
    * Webmail interface: `http://localhost:8081`

    _Available in: container, nixos._
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
      command = systemConfig.packages.mox;
      argv = [
        "-config"
        "/var/lib/mox/config/mox.conf"
        "serve"
      ];
    };

    runtimes = {
      container = {
        enable = true;
        setup = ''
          # Use a public DNSSEC-validating resolver
          echo "nameserver 8.8.8.8" >> /etc/resolv.conf

          # Add mox group and user required by mox server
          groupadd --system mox || true
          useradd --system --no-create-home --shell /sbin/nologin --gid mox mox || true

          # Create Mox keys and data files
          if ! [ -d /var/lib/mox ]; then
            mkdir -p /var/lib/mox && cd /var/lib/mox

            # Generate DKIM keys
            mkdir -p config/dkim
            ${systemConfig.packages.mox}/bin/mox dkim genrsa > config/dkim/dkima.rsa2048.privatekey.pkcs8.pem
            ${systemConfig.packages.mox}/bin/mox dkim genrsa > config/dkim/dkimb.rsa2048.privatekey.pkcs8.pem

            # Create data directory
            mkdir data
            chown mox:mox data
          fi
        '';
        packages = [
          pkgs.bash # required for entering the container
          pkgs.coreutils # required for mkdir, echo
          systemConfig.packages.mox # required for admin tasks
          pkgs.shadow # required for useradd
        ];
        composeFile = ./compose.yaml;
      };

      nixos = {
        enable = true;
        setup = ''
          # Create Mox keys and data files
          if ! [ -d /var/lib/mox ]; then
            mkdir -p /var/lib/mox && cd /var/lib/mox

            # Generate DKIM keys
            mkdir -p config/dkim
            ${systemConfig.packages.mox}/bin/mox dkim genrsa > config/dkim/dkima.rsa2048.privatekey.pkcs8.pem
            ${systemConfig.packages.mox}/bin/mox dkim genrsa > config/dkim/dkimb.rsa2048.privatekey.pkcs8.pem

            # Create data directory
            mkdir data
            chown mox:mox data
          fi
        '';
        packages = [ systemConfig.packages.mox ];
        extraConfig = {
          networking.enableIPv6 = false;
          # Use a public DNSSEC-validating resolver
          networking.nameservers = [ "8.8.8.8" ];

          users.groups.mox = { };
          users.users.mox = {
            isSystemUser = true;
            group = "mox";
          };
        };
        vm.forwardPorts = [
          "8080:8080"
          "8081:8081"
          "8082:8082"
        ];
      };
    };
  };

  test.script = ''
    curl="curl --retry 20 --retry-max-time 120 --retry-all-errors"

    $curl --location localhost:8080 | grep "Mox Account"
    $curl --location localhost:8081/admin | grep "Mox Admin"
    $curl --location localhost:8082/webmail | grep "Mox Webmail"
  '';
}
