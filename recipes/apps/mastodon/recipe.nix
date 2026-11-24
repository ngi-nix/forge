{
  forge-lib,
  lib,
  pkgs,
  config,
  ...
}:
let
  app = config.apps.mastodon;
  endpoint = app.services.resources.nginx.endpoints.web;

  inherit (app.parameters)
    port
    domain
    adminEmail
    adminPassword
    ;

  # An empty `publicUrl` parameter gives an address with the domain and the forwarded port.
  # Thus a changed `domain` or `port` parameter also changes the address.
  publicUrl =
    if app.parameters.publicUrl == "" then
      "http://${domain}:${toString endpoint.forwardedPort}"
    else
      app.parameters.publicUrl;

  # The scheme and the host of the public address, for example `http` and `localhost:8080`.
  publicScheme = lib.head (lib.splitString "://" publicUrl);
  publicHost = lib.last (lib.splitString "://" publicUrl);
  adminEmailDomain = lib.last (lib.splitString "@" adminEmail);

  mastodon = pkgs.pkgsOriginal.mastodon;

  # Internal ports of the service components and resources. The components and the
  # resources find each other by name, for example `web` or `postgres`.
  ports = {
    web = 3000;
    streaming = 4000;
    garage-s3 = 3900;
    garage-rpc = 3901;
    garage-web = 3902;
  };

  # Object storage for the media files. All components use the same storage.
  # Credentials for evaluation only. Do not use these values in production.
  s3 = {
    bucket = "mastodon";
    region = "garage";
    # Garage gets the bucket name from the `Host` header of a web request.
    webDomain = "mastodon.web.garage";
    keyId = "GK6d6173746f646f6e64656d6f";
    secretKey = "0e1b6c3a54b2a1d9b8f4c6e7d2a3f5b8c9e0d1f2a3b4c5d6e7f8091a2b3c4d5e";
  };

  # Environment of all service components.
  # It is equivalent to the environment of the NixOS module `services.mastodon`.
  environment = {
    RAILS_ENV = "production";
    NODE_ENV = "production";
    LOCAL_DOMAIN = domain;
    DB_HOST = "postgres";
    DB_PORT = 5432;
    DB_USER = "mastodon";
    DB_NAME = "mastodon";
    REDIS_HOST = "redis";
    REDIS_PORT = 6379;
    SMTP_SERVER = "localhost";
    SMTP_PORT = 25;
    SMTP_FROM_ADDRESS = "mastodon@${domain}";
    S3_ENABLED = "true";
    S3_BUCKET = s3.bucket;
    S3_ENDPOINT = "http://garage:${toString ports.garage-s3}";
    S3_REGION = s3.region;
    S3_FORCE_SINGLE_REQUEST = "true";
    # The media URLs point to the `/system/` path of the web server, which sends the requests to Garage.
    S3_PROTOCOL = publicScheme;
    S3_ALIAS_HOST = "${publicHost}/system";
    AWS_ACCESS_KEY_ID = s3.keyId;
    AWS_SECRET_ACCESS_KEY = s3.secretKey;
    ES_ENABLED = "false";

    # Secrets for evaluation only. All components must use the same values.
    # Do not use these values in production.
    SECRET_KEY_BASE = "8d872132f869ff60ef746e36cde7de30b7c1949aa4ead89b7afdda2a88d4fcebd06e8c0c861a3cd8e0e063b997e97a806c7417572a2ecbda52e1f503c1d303f7";
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY = "jjzdzcUaoIuvznnlsxbISBIztzfPPfjP";
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT = "2iNk5RyhDSMtqmX0X4e0l5nXznNLRmQa";
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY = "kvbGru1JvBq8EVuTkXQh2jwqJrLwm3JK";
    VAPID_PUBLIC_KEY = "BJRLvUnvJaxajd2JgMgCyvpvPfTIq1JOTg-oM5qQgM88-QFQI64amEgh8uaR7sLZQhVEk02r5LwsSWlnJRS4PUw=";
    VAPID_PRIVATE_KEY = "5h2jZOskmoqXU3wHo9LynuYBD84JvqNbULhw6uVBIzw=";
  };

  # Make a start script that runs in the Mastodon package directory.
  # The script sets `PATH`, because the container runtime does not set it.
  mkCommand =
    name: packages: script:
    pkgs.writeShellScriptBin "mastodon-${name}" ''
      set -e
      export PATH=${lib.makeBinPath ([ mastodon ] ++ packages)}''${PATH:+:$PATH}
      export LD_PRELOAD=${pkgs.jemalloc}/lib/libjemalloc.so
      cd ${mastodon}
      ${script}
    '';

  # Small PNG image for the media upload test.
  testImage = pkgs.runCommand "mastodon-test.png" { } ''
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==" \
      | ${pkgs.coreutils}/bin/base64 -d > $out
  '';

  healthcheck = port: path: {
    enable = true;
    test = [
      (lib.getExe pkgs.curl)
      "--fail"
      "--silent"
      "http://localhost:${toString port}${path}"
    ];
    # The container image includes only these packages.
    packages = [ pkgs.curl ];
    interval = "5s";
    timeout = "5s";
    startPeriod = "10s";
    retries = 120;
  };
in
{
  pkgs.mastodon = {
    build.builders.identity = {
      enable = true;
      derivation = mastodon;
    };
  };

  apps.mastodon = {
    displayName = "Mastodon";
    description = "Decentralized social network server, part of the fediverse.";
    longDescription = ''
      Mastodon is a free and decentralized social network server.
      Users publish short posts with text, images and videos, and follow other users.
      Mastodon uses the ActivityPub protocol, thus it can connect to other servers in the fediverse.
    '';
    categories = with forge-lib.categories; [ Network ];
    usage = ''
      The web interface is available on [${publicUrl}](${publicUrl}) (host port `${toString endpoint.forwardedPort}`).
      The first start prepares the database. This can take some minutes.
      Log in on [${publicUrl}/auth/sign_in](${publicUrl}/auth/sign_in) with the email `${adminEmail}` and the password `${adminPassword}`.
      This account has the `Owner` role.

      This configuration is for evaluation only. It uses plain HTTP, thus live updates over WebSocket do not operate and the server cannot federate with other servers.
      It also uses fixed secret keys, which are public.
      The uploaded media files are in a Garage object storage, which uses a fixed access key.
      Before you use Mastodon in production, change the `domain`, `publicUrl`, `adminEmail` and `adminPassword` parameters, and configure TLS, email delivery and new secret keys.
    '';

    icon = ./icon.svg;

    links = {
      website = "https://joinmastodon.org";
      source = "https://github.com/mastodon/mastodon";
      docs = "https://docs.joinmastodon.org";
    };

    parameters = {
      port = {
        value = 8080;
        description = "Port of the Mastodon web interface.";
      };
      domain = {
        value = "localhost";
        description = "Domain name of the server. It is part of the user addresses, for example `@alice@localhost`. Do not change it after the first start.";
      };
      publicUrl = {
        value = "";
        description = "Public address of the web interface, for example the address of a reverse proxy. The media file URLs use this address. If empty, it is `http://` with the domain and the port of the web interface.";
      };
      adminEmail = {
        value = "admin@localhost";
        description = "Email address of the administrator account. The first start creates this account.";
      };
      adminPassword = {
        value = "mastodon-admin";
        description = "Password of the administrator account. The first start sets this password.";
      };
    };

    ngi.grants = {
      Entrust = [ "Mastodon-Quoting" ];
      Commons = [ "Mastodon-for-institutions" ];
      Review = [ "Mastodon" ];
    };

    services = {
      # Rails web application. It also prepares the database.
      components.web = {
        process = {
          command = mkCommand "web" [ pkgs.ffmpeg-headless pkgs.file ] ''
            exec puma -C config/puma.rb
          '';
          environment = environment // {
            BIND = "0.0.0.0";
            PORT = ports.web;
            WEB_CONCURRENCY = 2;
            MAX_THREADS = 5;
          };
          # Load the database schema on the first start, then apply migrations.
          # The same steps are in the `mastodon-init-db` service of the NixOS module.
          preStart = lib.getExe (
            mkCommand "init-db" [ pkgs.postgresql ] ''
              export PGHOST=$DB_HOST PGPORT=$DB_PORT PGUSER=$DB_USER PGDATABASE=$DB_NAME
              tables=$(psql -t --csv -c "select count(*) from pg_class c \
                join pg_namespace s on s.oid = c.relnamespace \
                where s.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') \
                and s.nspname not like 'pg_temp%';")
              if [ "$tables" -eq 0 ]; then
                echo "Seeding database"
                SAFETY_ASSURED=1 rails db:schema:load
                rails db:seed
              else
                echo "Migrating database"
                rails db:migrate
              fi

              # Create the demo administrator account.
              if [ ! -e /var/lib/mastodon/.demo-admin ]; then
                # Skip the DNS check of the email domain.
                EMAIL_DOMAIN_ALLOWLIST=${lib.escapeShellArg adminEmailDomain} tootctl accounts create admin \
                  --email ${lib.escapeShellArg adminEmail} --confirmed --approve --role Owner \
                  || echo "The demo administrator account exists"
                ADMIN_EMAIL=${lib.escapeShellArg adminEmail} ADMIN_PASSWORD=${lib.escapeShellArg adminPassword} rails runner \
                  "User.find_by!(email: ENV['ADMIN_EMAIL']).update!(password: ENV['ADMIN_PASSWORD'])"
                touch /var/lib/mastodon/.demo-admin
              fi
            ''
          );
          user = "non-privileged";
          stateDir = "/var/lib/mastodon";
        };
        healthcheck = healthcheck ports.web "/health";
      };

      # Node.js server for live updates.
      components.streaming = {
        process = {
          command = mkCommand "streaming" [ ] ''
            exec ./run-streaming.sh
          '';
          environment = environment // {
            BIND = "0.0.0.0";
            PORT = ports.streaming;
          };
          user = "non-privileged";
          stateDir = "/var/lib/mastodon-streaming";
        };
        healthcheck = healthcheck ports.streaming "/api/v1/streaming/health";
        dependsOn = [ "web" ];
      };

      # Background jobs.
      components.sidekiq = {
        process = {
          command =
            mkCommand "sidekiq"
              [
                pkgs.ffmpeg-headless
                pkgs.file
              ]
              ''
                exec sidekiq -c 5 -r ${mastodon}
              '';
          environment = environment // {
            DB_POOL = 5;
          };
          user = "non-privileged";
          stateDir = "/var/lib/mastodon-sidekiq";
        };
        dependsOn = [ "web" ];
      };

      resources.postgres.nixosConfig = {
        services.postgresql = {
          enable = true;
          ensureDatabases = [ "mastodon" ];
          ensureUsers = [
            {
              name = "mastodon";
              ensureDBOwnership = true;
            }
          ];
        };
      };

      resources.redis.nixosConfig = {
        services.redis.servers.mastodon = {
          enable = true;
          port = 6379;
        };
      };

      # S3 compatible object storage for the media files.
      # The setup service makes the cluster layout, the access key and the bucket before the components start.
      resources.garage.nixosConfig =
        { config, ... }:
        {
          services.garage = {
            enable = true;
            package = pkgs.garage_2;
            settings = {
              replication_factor = 1;
              rpc_bind_addr = "[::]:${toString ports.garage-rpc}";
              # Secret for evaluation only. Do not use this value in production.
              rpc_secret = "5d1c5e8fd2b5cbd0a7fb5c0e0b9e3bdbd9d5d0f4c38a9cfd8c3e4a7b1c2d3e4f";
              s3_api = {
                s3_region = s3.region;
                api_bind_addr = "[::]:${toString ports.garage-s3}";
              };
              s3_web = {
                bind_addr = "[::]:${toString ports.garage-web}";
                root_domain = ".web.garage";
              };
            };
          };
          systemd.services.garage-setup = {
            description = "Prepare the Garage storage for Mastodon";
            wantedBy = [ "multi-user.target" ];
            before = [ "multi-user.target" ];
            after = [ "garage.service" ];
            requires = [ "garage.service" ];
            path = [ config.services.garage.package ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            # All steps are idempotent.
            script = ''
              until garage status >/dev/null 2>&1; do sleep 1; done
              if garage layout show | grep -q "Current cluster layout version: 0"; then
                garage layout assign -z dc1 -c 1G "$(garage node id -q | cut -d@ -f1)"
                garage layout apply --version 1
              fi
              garage key info mastodon >/dev/null 2>&1 \
                || garage key import --yes -n mastodon ${s3.keyId} ${s3.secretKey}
              garage bucket info ${s3.bucket} >/dev/null 2>&1 || garage bucket create ${s3.bucket}
              garage bucket allow --read --write --owner ${s3.bucket} --key mastodon
              # Let the web endpoint serve the media files without authentication.
              garage bucket website --allow ${s3.bucket}
            '';
          };
        };

      # Mastodon forces HTTPS in production.
      # The proxy tells Mastodon that the request uses HTTPS and changes the redirects back to HTTP.
      # The proxy also changes the scheme of the `Origin` header to HTTPS, because the CSRF protection of Rails compares it to the scheme of the request.
      # The proxy sends the public host and port in the `Host` header, because Rails does not use the `X-Forwarded-Port` header to make the base URL.
      resources.nginx = {
        role = "frontend";
        endpoints.web.port = port;
        nixosConfig =
          let
            proxyConfig = ''
              proxy_set_header Host ${publicHost};
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto https;
              proxy_set_header Origin $mastodon_origin;
              proxy_redirect https:// http://;
              proxy_hide_header Strict-Transport-Security;
            '';
          in
          {
            services.nginx = {
              enable = true;
              appendHttpConfig = ''
                map $http_origin $mastodon_origin {
                  default $http_origin;
                  "~^http://(?<origin_host>.+)$" https://$origin_host;
                }
              '';
              virtualHosts.localhost = {
                listen = [
                  {
                    addr = "0.0.0.0";
                    inherit port;
                  }
                  {
                    addr = "[::]";
                    inherit port;
                  }
                ];
                root = "${mastodon}/public/";
                locations."/system/" = {
                  proxyPass = "http://garage:${toString ports.garage-web}/";
                  recommendedProxySettings = false;
                  extraConfig = ''
                    proxy_set_header Host ${s3.webDomain};
                  '';
                };
                locations."/".tryFiles = "$uri @proxy";
                locations."@proxy" = {
                  proxyPass = "http://web:${toString ports.web}";
                  proxyWebsockets = true;
                  recommendedProxySettings = false;
                  extraConfig = proxyConfig;
                };
                locations."/api/v1/streaming" = {
                  proxyPass = "http://streaming:${toString ports.streaming}";
                  proxyWebsockets = true;
                  recommendedProxySettings = false;
                  extraConfig = proxyConfig;
                };
              };
            };
          };
      };

      runtimes = {
        container = {
          enable = true;
          # The components connect over the container network.
          resources.postgres.nixosConfig = {
            services.postgresql.enableTCPIP = true;
            services.postgresql.authentication = ''
              host all all 0.0.0.0/0 trust
              host all all ::0/0 trust
            '';
          };
          resources.redis.nixosConfig = {
            services.redis.servers.mastodon = {
              bind = null;
              settings.protected-mode = "no";
            };
          };
        };
        nixos = {
          enable = true;
          vm.memorySize = 4096;
          nixosConfig = {
            services.postgresql.authentication = ''
              host all all 127.0.0.1/32 trust
              host all all ::1/128 trust
            '';
          };
        };
      };
    };

    test.services.nixosConfig.virtualisation = {
      memorySize = 4096;
      # The three component images of Mastodon do not fit on the default disk of the container test.
      diskSize = lib.mkForce 30720;
    };
    test.services.script = ''
      curl="curl --retry 60 --retry-max-time 600 --retry-all-errors --fail"
      base=localhost:${toString port}

      $curl $base/api/v1/instance | grep '"title":"Mastodon"' >/dev/null
      $curl $base/about | grep -i "mastodon" >/dev/null
      $curl $base/api/v1/streaming/health | grep "OK" >/dev/null

      # Log in as the demo administrator.
      jar=$(mktemp)
      token=$($curl --cookie-jar "$jar" $base/auth/sign_in \
        | grep -o 'name="authenticity_token" value="[^"]*"' | sed 's/.*value="//; s/"$//')
      # Send the `Origin` header like a web browser.
      $curl --cookie "$jar" --cookie-jar "$jar" $base/auth/sign_in \
        -H "Origin: http://$base" \
        --data-urlencode authenticity_token="$token" \
        --data-urlencode user[email]=${lib.escapeShellArg adminEmail} \
        --data-urlencode user[password]=${lib.escapeShellArg adminPassword} >/dev/null
      $curl --cookie "$jar" $base/settings/profile | grep "auth/sign_out" >/dev/null

      # Upload a media file with the access token of the web interface.
      # Then get the file through the web server.
      access_token=$($curl --cookie "$jar" $base/home \
        | grep -o '"access_token":"[^"]*"' | sed 's/.*:"//; s/"$//')
      auth="Authorization: Bearer $access_token"
      media_id=$($curl -H "$auth" -F file=@${testImage} $base/api/v2/media \
        | grep -o '"id":"[^"]*"' | head -n 1 | sed 's/.*:"//; s/"$//')
      url=""
      for _ in $(seq 1 60); do
        url=$($curl -H "$auth" $base/api/v1/media/"$media_id" \
          | grep -o '"url":"[^"]*"' | head -n 1 | sed 's/.*:"//; s/"$//')
        [ -n "$url" ] && break
        sleep 2
      done
      echo "Media URL: $url"
      case "$url" in
        ${publicUrl}/system/*) ;;
        *) echo "Unexpected media URL"; exit 1 ;;
      esac
      $curl --output /dev/null --write-out "%{content_type}" "$url" | grep "^image/png" >/dev/null
    '';
  };
}
