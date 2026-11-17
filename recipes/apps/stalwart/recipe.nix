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
  inherit (app.parameters) hostname adminPassword;
  # `override` keeps the earlier values of all parameters, thus `publicUrl`
  # cannot have a default value that uses `hostname`.
  adminUrl =
    if app.parameters.publicUrl != "" then
      app.parameters.publicUrl
    else
      "https://${hostname}:${toString endpoints.https.forwardedPort}";
  adminCredentials = "admin:${adminPassword}";

  stalwart = pkgs.pkgsOriginal.stalwart_1_0;
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

      The web administration interface is available on [${adminUrl}/admin](${adminUrl}/admin).
      Stalwart uses a self-signed TLS certificate, thus the web browser shows a security warning.
      Log in with the user `admin` and the password `${adminPassword}`.
      The login does not work on the HTTP port `${toString endpoints.web.forwardedPort}`.

      Mail ports on the host:

      - SMTP: `${toString endpoints.smtp.forwardedPort}`
      - SMTP submission with TLS: `${toString endpoints.submissions.forwardedPort}`
      - IMAP with TLS: `${toString endpoints.imaps.forwardedPort}`

      This configuration is for evaluation only. Before you use Stalwart in production, change the `adminPassword`, `hostname` and `publicUrl` parameters and configure TLS and DNS.
    '';

    icon = ./icon.svg;

    parameters = {
      hostname = {
        value = "localhost";
        description = "Host name of the server.";
      };
      publicUrl = {
        value = "";
        description = "Public HTTPS address of the server, for example the address of a reverse proxy. The web administration interface works only on this address. If empty, the address is `https://<hostname>:<forwarded HTTPS port>`.";
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
            STALWART_PUBLIC_URL = adminUrl;
            # The container image has no system CA certificates.
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            STALWART_RECOVERY_ADMIN = adminCredentials;
            # The service starts as root to bind the privileged ports, and then
            # runs as this user, which the runtimes create for the service component.
            RUN_AS_USER = "stalwart";
            RUN_AS_GROUP = "stalwart";
          };
          preStart = ''
            mkdir -p ${stateDir}/data
            chown -R stalwart:stalwart ${stateDir}
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
            "http://localhost:8080/healthz/live"
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
      curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"

      $curl --fail localhost:8080/healthz/live
      $curl --fail --user ${lib.escapeShellArg adminCredentials} localhost:8080/jmap/session | grep -i "urn:ietf:params:jmap:core" >/dev/null

      # The web admin login trusts only the HTTPS public address.
      # The test machine reaches port 443 directly, thus connect to it with the forwarded address.
      $curl --fail --insecure --connect-to ::localhost:443 \
        ${adminUrl}/.well-known/oauth-protected-resource | grep -F '"${adminUrl}' >/dev/null
      status=$(curl -s -o /dev/null -w '%{http_code}' localhost:8080/.well-known/oauth-protected-resource)
      if [ "$status" != 404 ]; then
        echo "HTTP address is trusted, status: $status" >&2
        exit 1
      fi

      # Stalwart must not run as root after it binds the ports.
      uids=$(ps -C stalwart -o uid=)
      if [ -z "$uids" ] || echo "$uids" | grep -qw 0; then
        echo "stalwart runs as uid: $uids" >&2
        exit 1
      fi
    '';
  };
}
