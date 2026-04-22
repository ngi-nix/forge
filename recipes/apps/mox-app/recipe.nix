{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "mox-app";
  displayName = "Mox";
  description = "Modern full-featured open source secure mail server for low-maintenance self-hosted email.";
  usage = ''
    Mox is a modern, full-featured, open source secure mail server providing
    SMTP, IMAP4, webmail, SPF/DKIM/DMARC, and more.

    #### Administration

    Set admin password:
    ```
    echo "adminpassword" | mox -config /var/lib/mox/config/mox.conf setadminpassword
    chown mox /var/lib/mox/config/adminpasswd
    ```

    Access the admin web interface at `http://localhost:8080/admin`.

    List of available commands:
    ```
    mox --help
    ```

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
      command = pkgs.mypkgs.mox;
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
            ${pkgs.mypkgs.mox}/bin/mox dkim genrsa > config/dkim/dkima.rsa2048.privatekey.pkcs8.pem
            ${pkgs.mypkgs.mox}/bin/mox dkim genrsa > config/dkim/dkimb.rsa2048.privatekey.pkcs8.pem

            # Create data directory
            mkdir data
            chown mox:mox data
          fi
        '';
        packages = [
          pkgs.bash # required for entering the container
          pkgs.coreutils # required for mkdir, echo
          pkgs.mypkgs.mox # required for admin tasks
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
            ${pkgs.mypkgs.mox}/bin/mox dkim genrsa > config/dkim/dkima.rsa2048.privatekey.pkcs8.pem
            ${pkgs.mypkgs.mox}/bin/mox dkim genrsa > config/dkim/dkimb.rsa2048.privatekey.pkcs8.pem

            # Create data directory
            mkdir data
            chown mox:mox data
          fi
        '';
        extraConfig = {
          networking.enableIPv6 = false;
          # Use a public DNSSEC-validating resolver
          networking.nameservers = [ "8.8.8.8" ];

          users.groups.mox = { };
          users.users.mox = {
            isSystemUser = true;
            group = "mox";
          };

          # Make mox package available for admin tasks
          environment.systemPackages = [ pkgs.mypkgs.mox ];
        };
        vm.forwardPorts = [
          "8080:80"
        ];
      };
    };
  };

  test.script = ''
    curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

    $curl localhost | grep "Mox Account"
  '';
}
