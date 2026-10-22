{
  config,
  forgeConfig,
  lib,
  pkgs,
  ...
}:

let
  app = config.apps.krill;

  unixSocket = "/var/lib/krill/krill.sock";

  usageSnippets = forgeConfig.forge.snippets.usage app;
in
{
  pkgs.krill = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.krill;
    };
  };

  apps.krill = {
    displayName = "Krill";
    description = "RPKI Certificate Authority and Publication Server.";
    longDescription = ''
      Krill is a Resource Public Key Infrastructure
      [(RPKI)](https://en.wikipedia.org/wiki/Resource_Public_Key_Infrastructure)
      daemon, featuring a Certificate Authority (CA) and Publication Server. It
      allows operators to create Route Origin Authorizations (ROAs) for their IP
      address space.
    '';
    usage = ''
      First, ${usageSnippets.run-container} or ${usageSnippets.run-nixos}.

      #### Web Interface

      Open the [web interface](https://localhost:3000) and log in with the
      admin token, which by default is set to `${app.data.adminToken}`.

      > [!CAUTION]
      > In default configuration, admin token is set to `${app.data.adminToken}`
      > and is stored in the Nix store, which is world-readable. In production
      > configuration, pass it as the `KRILL_ADMIN_TOKEN` environment variable.

      #### Create Certificate Authority

      Enter the running container

      ```bash
      podman exec -it krill_krill_1 bash
      ```

      or log in to the NixOS VM (the console logs in automatically as root),
      then use `krillc` to manage Certificate Authorities

      ```bash
      export KRILL_CLI_SERVER="unix://${unixSocket}"
      export KRILL_CLI_TOKEN="${app.data.adminToken}"
      krillc info
      krillc add --ca example-ca
      krillc list
      ```

      For more information, see
      [Get started instrucitons](https://krill.docs.nlnetlabs.nl/en/stable/get-started.html).
    '';

    links = {
      website = "https://www.nlnetlabs.nl/projects/routing/krill";
      docs = "https://krill.docs.nlnetlabs.nl";
      source = "https://github.com/NLnetLabs/krill";
    };

    ngi.grants = {
      Entrust = [
        "Krill-BGP"
        "Krill-kvx"
      ];
    };

    icon = ./icon.svg;

    # WARNING: for testing purposes only, the token is stored in the Nix store.
    data.adminToken = "krill";

    services = {
      components.krill = {
        process.configData."krill.conf" = {
          source = ./krill.conf;
          path = "krill.conf";
        };
        process.command = lib.getExe' pkgs.krill "krill";
        process.argv = [
          "--config"
          "$XDG_CONFIG_HOME/krill.conf"
        ];
        process.environment = {
          KRILL_ADMIN_TOKEN = "${app.data.adminToken}";
          # Required for downloading BGP announcements (RISwhois)
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
        process.ports = [ "3000:3000" ];
      };

      runtimes = {
        container = {
          enable = true;
          components.krill.packages = [
            pkgs.bash # required for entering the container
            pkgs.coreutils
            pkgs.krill # required for krillc
          ];
        };

        nixos = {
          enable = true;
          packages = [
            pkgs.krill # required for krillc
          ];
        };
      };
    };

    test.services = {
      packages = [ pkgs.krill ];
      script = ''
        curl --insecure -f --retry 10 --retry-max-time 120 --retry-all-errors \
          https://localhost:3000/health

        # The Unix socket is not reachable from the host in the container runtime
        export KRILL_CLI_SERVER="https://localhost:3000/"
        export KRILL_CLI_TOKEN="${app.data.adminToken}"
        krillc add --ca test-ca
        krillc list | grep test-ca
      '';
    };
  };
}
