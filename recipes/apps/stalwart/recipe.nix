{
  forge-lib,
  lib,
  config,
  pkgs,
  ...
}:
let
  app = config.apps.stalwart;
  endpoints = app.services.components.stalwart.endpoints;
  stateDir = app.services.components.stalwart.process.stateDir;

  inherit (app.parameters) hostname publicUrl adminPassword;

  adminCredentials = "admin:${adminPassword}";
  webPort = toString endpoints.web.port;

  stalwart = pkgs.pkgsOriginal.stalwart_1;
in
{
  pkgs.stalwart = {
    build.builders.identity = {
      enable = true;
      derivation = stalwart;
    };
  };

  apps.stalwart = {
    displayName = "Stalwart";
    description = "All-in-one mail and collaboration server.";
    categories = with forge-lib.categories; [ Email ];
    usage = ''
      Stalwart is a mail and collaboration server with SMTP, IMAP, JMAP, POP3, CalDAV, CardDAV and WebDAV support.

      The web administration interface is available on [${publicUrl}/admin](${publicUrl}/admin).
      Stalwart uses a self-signed TLS certificate, thus the web browser shows a security warning.
      Log in with the user `admin` and the password `${adminPassword}`.
      The login does not work on the HTTP port `${toString endpoints.web.forwardedPort}`.

      Mail ports on the host:

      - SMTP: `${toString endpoints.smtp.forwardedPort}`
      - SMTP submission with TLS: `${toString endpoints.submissions.forwardedPort}`
      - IMAP with TLS: `${toString endpoints.imaps.forwardedPort}`
      - POP3 with TLS: `${toString endpoints.pop3s.forwardedPort}`
      - ManageSieve: `${toString endpoints.sieve.forwardedPort}`

      This configuration is for evaluation only. Before you use Stalwart in production, change the `adminPassword`, `hostname` and `publicUrl` parameters and configure TLS and DNS.
    '';

    icon = ./icon.svg;

    parameters = {
      hostname = {
        value = "localhost";
        description = "Host name of the server.";
      };
      publicUrl = {
        value = "https://${hostname}:${toString endpoints.https.forwardedPort}";
        description = "Public HTTPS address of the server, for example the address of a reverse proxy. The web administration interface works only on this address.";
      };
      adminPassword = {
        value = "admin";
        description = "Password of the `admin` user of the web administration interface.";
      };
    };

    links = {
      website = "https://stalw.art";
      source = "https://github.com/stalwartlabs/stalwart";
      docs = "https://stalw.art/docs";
    };

    ngi.grants = {
      Core = [ "Stalwart-Collaboration" ];
      Entrust = [ "Stalwart" ];
    };

    services = {
      components.stalwart = {
        process = {
          command = stalwart;
          argv = [ "--config=$XDG_CONFIG_HOME/config.json" ];
          # Stalwart keeps all other settings in its database.
          configData."config.json" = {
            text = builtins.toJSON {
              "@type" = "RocksDb";
              path = "${stateDir}/data";
            };
            path = "config.json";
          };
          environment = {
            STALWART_HOSTNAME = hostname;
            # The web admin login works only on this HTTPS address.
            STALWART_PUBLIC_URL = publicUrl;
            # The container image has no system CA certificates.
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            STALWART_RECOVERY_ADMIN = adminCredentials;
            # The service starts as root to bind the privileged ports, and then
            # runs as this user, which the runtimes create for the service component.
            RUN_AS_USER = "stalwart";
            RUN_AS_GROUP = "stalwart";
          };
          # Stalwart creates all other files as the `stalwart` user.
          preStart = ''
            mkdir -p ${stateDir}/data
            chown stalwart:stalwart ${stateDir} ${stateDir}/data
          '';
          packages = [ pkgs.coreutils ];
          user = "root";
        };
        endpoints = {
          smtp = {
            port = 25;
            appProtocol = "smtp";
          };
          submissions = {
            port = 465;
            appProtocol = "smtps";
          };
          imaps = {
            port = 993;
            appProtocol = "imaps";
          };
          pop3s = {
            port = 995;
            appProtocol = "pop3s";
          };
          sieve = {
            port = 4190;
            appProtocol = "managesieve";
          };
          https = {
            port = 443;
            appProtocol = "https";
          };
          web.port = 8080;
        };
        healthcheck = {
          enable = true;
          test = [
            "${lib.getExe pkgs.curl}"
            "-fs"
            "http://localhost:${webPort}/healthz/live"
          ];
          startPeriod = "30s";
        };
      };

      runtimes = {
        container.enable = true;
        nixos.enable = true;
      };
    };

    test.services.script = ''
      curl="curl --fail --silent --retry 10 --retry-max-time 120 --retry-all-errors"

      # The service is up and the admin can log in.
      $curl localhost:${webPort}/healthz/live
      $curl --user ${lib.escapeShellArg adminCredentials} localhost:${webPort}/jmap/session \
        | grep "urn:ietf:params:jmap:core" >/dev/null
    '';
  };
}
