{
  forge-lib,
  config,
  lib,
  pkgs,
  ...
}:
let
  app = config.apps.cryptpad;
  endpoints = app.services.components.cryptpad.endpoints;
  stateDir = "/var/lib/cryptpad";

  inherit (app.parameters)
    webPort
    sandboxPort
    ;

  # An empty URL parameter gives an address on `localhost` with the forwarded port.
  # Thus a changed port parameter also changes the address.
  urlOrLocalhost =
    url: endpoint: if url == "" then "http://localhost:${toString endpoint.forwardedPort}" else url;
  publicUrl = urlOrLocalhost app.parameters.publicUrl endpoints.web;
  sandboxUrl = urlOrLocalhost app.parameters.sandboxUrl app.services.resources.sandbox-proxy.endpoints.sandbox;

  cryptpad = pkgs.pkgsOriginal.cryptpad;

  # The CryptPad configuration file is a JavaScript file that exports a JSON value.
  # The NixOS module `services.cryptpad` makes a similar file. Most of these values are its defaults.
  configFile = pkgs.writeText "cryptpad-config.js" ''
    module.exports = ${
      builtins.toJSON {
        # The origins must be the URLs that the web browser uses.
        httpUnsafeOrigin = publicUrl;
        httpSafeOrigin = sandboxUrl;
        # Listen on all addresses, so that forwarded ports and other containers can reach the service.
        httpAddress = "0.0.0.0";
        httpPort = webPort;
        # Internal port. The web server sends the WebSocket requests to it.
        websocketPort = 3003;
        logToStdout = true;
        logLevel = "info";
        # Disable telemetry.
        blockDailyCheck = true;
      }
    }
  '';
in
{
  pkgs.cryptpad = {
    build.builders.identity = {
      enable = true;
      derivation = cryptpad;
    };
  };

  apps.cryptpad = {
    displayName = "CryptPad";
    description = "End-to-end encrypted collaboration suite.";
    longDescription = ''
      CryptPad is a collaboration suite with rich text documents, spreadsheets, presentations, forms, a whiteboard, a kanban board and a drive.
      The web browser encrypts all documents before it sends them to the server, thus the server cannot read them.
      Users can work without an account, or register an account to keep their documents in a drive.
    '';
    usage = ''
      The web interface is available on [${publicUrl}](${publicUrl}).
      You can use CryptPad without an account, or you can register a new account in the web interface.

      To make the first administrator account, open the installation link from the log of the `cryptpad` service component (`journalctl -u cryptpad` in the NixOS runtime).

      CryptPad uses a second origin as a sandbox: [${sandboxUrl}](${sandboxUrl}). The web browser must be able to reach it.

      Use exactly these addresses in the web browser. CryptPad does not open documents from a different address, for example `127.0.0.1` in place of `localhost`, or a different port.
      If you change the `webPort` or `sandboxPort` parameter, keep the `publicUrl` and `sandboxUrl` parameters empty, or change them to the same ports.

      This configuration is for evaluation only. Before you use CryptPad in production, configure TLS and two different domain names, and change the `publicUrl` and `sandboxUrl` parameters.
    '';

    categories = with forge-lib.categories; [ Office ];

    icon = ./icon.svg;

    parameters = {
      webPort = {
        value = 3000;
        description = "Port of the CryptPad web interface.";
      };
      sandboxPort = {
        value = 3001;
        description = "Port of the CryptPad sandbox origin.";
      };
      publicUrl = {
        value = "";
        description = "Public address of the CryptPad web interface (`httpUnsafeOrigin`). If empty, it is `http://localhost:` with the port of the web interface.";
      };
      sandboxUrl = {
        value = "";
        description = "Public address of the CryptPad sandbox (`httpSafeOrigin`). It must be different from `publicUrl`. If empty, it is `http://localhost:` with the port of the sandbox.";
      };
    };

    links = {
      website = "https://cryptpad.org";
      source = "https://github.com/cryptpad/cryptpad";
      docs = "https://docs.cryptpad.org";
    };

    ngi.grants = {
      Commons = [
        "CryptPad-Notes"
        "Cryptpad-scaling"
      ];
      Entrust = [ "CryptPad-Blueprints" ];
      Review = [
        "Cryptpad"
        "CryptPad-Auth"
        "Cryptpad-Communities"
        "Cryptpad-Directory"
        "CryptPadForms"
        "CryptPad-QA"
        "CryptPad-WCAG"
      ];
    };

    services = {
      components.cryptpad = {
        process = {
          # The `cryptpad` executable makes links to the source directories in the working directory.
          # It also makes the `customize` directory there. The working directory is `stateDir`.
          command = cryptpad;
          environment = {
            CRYPTPAD_CONFIG = "${configFile}";
            HOME = stateDir;
          };
          inherit stateDir;
        };
        endpoints.web.port = webPort;
        healthcheck = {
          enable = true;
          test = [
            "${lib.getExe pkgs.curl}"
            "-fs"
            "http://localhost:${toString webPort}/api/config"
          ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "5s";
          retries = 60;
          packages = [ pkgs.curl ];
        };
      };

      # CryptPad does not listen on a sandbox port when `httpSafeOrigin` is set.
      # Nginx sends the requests for the sandbox origin to the CryptPad server.
      resources.sandbox-proxy = {
        role = "frontend";
        endpoints.sandbox.port = sandboxPort;
        nixosConfig = {
          services.nginx = {
            enable = true;
            virtualHosts.cryptpad-sandbox = {
              listen = [
                {
                  addr = "0.0.0.0";
                  port = sandboxPort;
                }
              ];
              locations."/" = {
                proxyPass = "http://cryptpad:${toString webPort}";
                proxyWebsockets = true;
                extraConfig = ''
                  client_max_body_size 150m;
                '';
              };
            };
          };
        };
      };

      runtimes = {
        container.enable = true;
        nixos.enable = true;
      };
    };

    # The container image is large (approximately 2 GiB).
    # The default disk of the test VM does not have sufficient space to load it.
    test.services.nixosConfig.virtualisation.diskSize = lib.mkForce 16384;

    test.services.script = ''
      curl="curl --fail --silent --retry 10 --retry-max-time 120 --retry-all-errors"

      # The web interface and the sandbox respond.
      $curl localhost:${toString webPort} | grep -i "cryptpad" >/dev/null
      $curl localhost:${toString sandboxPort}/sheet/inner.html | grep -i "cryptpad" >/dev/null

      # The server tells the web browser the configured origins.
      $curl localhost:${toString webPort}/api/config | grep ${lib.escapeShellArg sandboxUrl} >/dev/null

      # The web server sends WebSocket requests to the internal WebSocket server.
      # The connection stays open after the upgrade, thus curl stops at the time limit.
      response=$(curl --silent --include --max-time 5 \
        --header "Connection: Upgrade" \
        --header "Upgrade: websocket" \
        --header "Sec-WebSocket-Version: 13" \
        --header "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
        localhost:${toString webPort}/cryptpad_websocket || true)
      echo "$response" | grep "101 Switching Protocols" >/dev/null
    '';
  };
}
