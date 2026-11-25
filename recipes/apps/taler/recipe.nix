{
  forge-lib,
  config,
  lib,
  pkgs,
  ...
}:
let
  app = config.apps.taler;
  inherit (app.parameters) port currency adminPassword;
  webPort = toString app.services.components.merchant-httpd.endpoints.web.forwardedPort;

  taler-merchant = pkgs.pkgsOriginal.taler-merchant;
  dbName = "taler-merchant";

  # The configuration that all merchant processes use.
  # `database` is the host name of the database resource.
  talerConf = lib.generators.toINI { } {
    taler = {
      CURRENCY = currency;
      CURRENCY_ROUND_UNIT = "${currency}:0.01";
    };
    merchant = {
      SERVE = "tcp";
      PORT = port;
      DB = "postgres";
    };
    merchantdb-postgres = {
      CONFIG = "postgres://${dbName}@database/${dbName}";
      SQL_DIR = "${taler-merchant}/share/taler/sql/merchant/";
    };
  };

  mkMerchantComponent =
    name: extraConfig:
    lib.recursiveUpdate {
      process = {
        command = lib.getExe' taler-merchant "taler-merchant-${name}";
        argv = [
          "-c"
          "$XDG_CONFIG_HOME/taler.conf"
        ];
        configData."taler.conf" = {
          text = talerConf;
          path = "taler.conf";
        };
        # Taler keeps its data and cache files below `$HOME`.
        # Use the state directory of the component.
        environment.HOME = "/var/lib/merchant-${name}";
        # `taler-merchant-depositcheck` finds other programs in `PATH`.
        packages = [ taler-merchant ];
      };
    } extraConfig;
in
{
  pkgs.taler-merchant = {
    build.builders.identity = {
      enable = true;
      derivation = taler-merchant;
    };
  };

  apps.taler = {
    displayName = "GNU Taler";
    description = "Merchant backend of the GNU Taler payment system.";
    longDescription = ''
      GNU Taler is a privacy-preserving electronic payment system. Customers pay with a wallet.
      The exchange keeps the payments anonymous for the customer, but the merchant income is visible to tax authorities.
      This app runs the merchant backend with its web interface. A shop uses the merchant backend to make orders and to receive payments.
    '';
    usage = ''
      The merchant web interface is available on [http://localhost:${webPort}/webui/](http://localhost:${webPort}/webui/).
      Log in to the instance `admin` with the password `${adminPassword}`.

      The backend uses the currency `${currency}`. To receive payments, add a bank account to the instance and connect to an exchange for this currency.

      This configuration is for evaluation only. Before you use the merchant backend in production, change the `adminPassword` and `currency` parameters, add a bank account and configure TLS.

      > [!CAUTION]
      > In default configuration, the password of the `admin` instance is `${adminPassword}`.
      > It is stored in the Nix store, which is world-readable.
      > After the first login, change the password in the web interface.
    '';

    categories = with forge-lib.categories; [ Finance ];

    icon = ./icon.svg;

    parameters = {
      port = {
        value = 8083;
        description = "Port of the merchant HTTP API and web interface.";
      };
      currency = {
        value = "KUDOS";
        description = "Currency of the merchant backend. `KUDOS` is a test currency.";
      };
      adminPassword = {
        value = "admin-password";
        description = "Initial password of the `admin` instance. The first start sets this password.";
      };
    };

    links = {
      website = "https://taler.net";
      source = "https://git.taler.net/merchant.git";
      docs = "https://docs.taler.net/taler-merchant-manual.html";
    };

    ngi.grants = {
      Entrust = [ "GNUTaler-LocalCurrencies" ];
      Review = [
        "GNUTaler"
        "GNUTaler-KYC"
      ];
    };

    services = {
      components = {
        # The HTTP server. It also makes the database tables and the `admin` instance.
        merchant-httpd = mkMerchantComponent "httpd" {
          # `taler-merchant-dbinit` runs `psql`.
          process.packages = [
            taler-merchant
            pkgs.postgresql
          ];
          process.preStart = ''
            ${lib.getExe' taler-merchant "taler-merchant-dbinit"} -c "$XDG_CONFIG_HOME/taler.conf"

            # Make the `admin` instance with the initial password, if the instance does not exist.
            # Later starts do not change the password, thus a password change in the web interface stays.
            # The `taler-merchant-passwd` command makes the instance if it does not exist.
            # The password is an argument, because the `TALER_MERCHANT_PASSWORD` variable does not work in version 1.3.0.
            if ! psql ${lib.escapeShellArg "postgres://${dbName}@database/${dbName}"} --tuples-only --no-align \
              --command "SELECT 1 FROM merchant.merchant_instances WHERE merchant_id = 'admin'" | ${lib.getExe pkgs.gnugrep} -q 1; then
              ${lib.getExe' taler-merchant "taler-merchant-passwd"} -c "$XDG_CONFIG_HOME/taler.conf" -i admin ${lib.escapeShellArg adminPassword}
            fi
          '';
          endpoints.web.port = port;
          healthcheck = {
            enable = true;
            test = [
              "curl"
              "--fail"
              "--silent"
              "http://localhost:${toString port}/config"
            ];
            packages = [ pkgs.curl ];
            interval = "3s";
            timeout = "3s";
            retries = 20;
          };
        };
      }
      # The background processes. They start after `merchant-httpd` is healthy,
      # thus after the database tables exist.
      // lib.genAttrs' [ "webhook" "wirewatch" "depositcheck" "exchangekeyupdate" ] (
        name:
        lib.nameValuePair "merchant-${name}" (
          mkMerchantComponent name {
            dependsOn = [ "merchant-httpd" ];
          }
        )
      );

      resources.database.nixosConfig = {
        services.postgresql = {
          enable = true;
          ensureDatabases = [ dbName ];
          ensureUsers = [
            {
              name = dbName;
              ensureDBOwnership = true;
            }
          ];
        };
      };

      runtimes = {
        container = {
          enable = true;
          resources.database.nixosConfig = {
            services.postgresql.enableTCPIP = true;
            services.postgresql.authentication = ''
              host all all 0.0.0.0/0 trust
              host all all ::0/0 trust
            '';
          };
        };
        nixos = {
          enable = true;
          nixosConfig = {
            services.postgresql.authentication = ''
              local all all trust
              host all all 127.0.0.1/32 trust
              host all all ::1/128 trust
            '';
          };
        };
      };
    };

    # The container test loads one image for each component.
    # The default disk of the test machine is too small for these images.
    test.services.nixosConfig.virtualisation.diskSize = lib.mkForce 8192;

    test.services.script = ''
      curl="curl --fail --silent --retry 10 --retry-max-time 120 --retry-all-errors"
      url="localhost:${toString port}"

      # The service is up and serves the web interface.
      $curl $url/config | grep "taler-merchant" >/dev/null
      $curl --location $url/webui/ | grep -i "taler" >/dev/null
      # The admin can log in.
      $curl --user ${lib.escapeShellArg "admin:${adminPassword}"} --json '{"scope":"readonly"}' \
        $url/private/token | grep "access_token" >/dev/null
    '';
  };
}
