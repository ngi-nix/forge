{
  pkgs,
  lib,
  ...
}:

let
  pixelfed = pkgs.pixelfed;
  phpPkg = pixelfed.phpPackage;

  pixelfedEnv = {
    APP_NAME = "Pixelfed";
    APP_ENV = "production";
    APP_KEY = "base64:x/cMhKq1nL8e2V0rA5zP4vG7tB9wD2xF5yH8sJ1kMNo=";
    APP_DEBUG = "false";
    APP_URL = "http://localhost:8080";
    FORCE_HTTPS_URLS = "false";
    SESSION_SECURE_COOKIE = "false";
    DB_CONNECTION = "pgsql";
    DB_HOST = "pixelfed-extracomponents";
    DB_PORT = "5432";
    DB_DATABASE = "pixelfed";
    DB_USERNAME = "pixelfed";
    DB_PASSWORD = "pixelfed";
    REDIS_HOST = "pixelfed-extracomponents";
    REDIS_PORT = "6379";
    REDIS_CLIENT = "phpredis";
    PHP_INI_SCAN_DIR = "${phpPkg}/lib";
  };
in
{
  apps.pixelfed = {
    displayName = "Pixelfed";
    description = "Photo Sharing. For Everyone.";
    usage = ''
      Pixelfed is an open-source, federated photo sharing platform.

      ##### Generate an APP_KEY

      To generate a new `APP_KEY`, use the `--show` flag so it prints to the console instead of trying to modify the read-only `.env` file:

      **Containers:**
      ```bash
      podman-compose -f result/*/compose.yaml exec pixelfed-web pixelfed-manage key:generate --show
      ```

      **NixOS:**
      ```
      pixelfed-manage key:generate --show
      ```

      ##### Setup admin account

      You can generate your first admin user using `pixelfed-manage user:create` which will prompt for details, or pass the arguments like below.

      **Containers:**
      ```bash
      podman-compose -f result/*/compose.yaml exec pixelfed-web pixelfed-manage user:create \
        --name="Main User" \
        --username="main" \
        --email="main@localhost" \
        --password="main1234" \
        --is_admin=1 \
        --confirm_email=0
      ```

      **For VM / NixOS Deployments:**
      Drop into the machine shell and run:
      ```bash
      pixelfed-manage user:create \
        --name="Main User" \
        --username="main" \
        --email="main@localhost" \
        --password="main1234" \
        --is_admin=1 \
        --confirm_email=0
      ```

      Pixelfed will be available in [http://localhost:8080](http://localhost:8080).
    '';

    links = {
      source = "https://github.com/pixelfed/pixelfed";
      docs = "https://docs.pixelfed.org/";
      website = "https://pixelfed.org/";
    };

    ngi.grants = {
      Entrust = [
        "Pixelfed-Groups"
        "PixelDroid-MediaEditor"
      ];
      Review = [
        "Pixelfed"
        "PixelFedLive"
      ];
    };

    services = {
      extraComponents = {
        pixelfed-extracomponents = {
          nixosConfig = {
            services.postgresql = {
              enable = true;
              package = pkgs.postgresql_17;
              ensureDatabases = [ "pixelfed" ];
              ensureUsers = [
                {
                  name = "pixelfed";
                  ensureDBOwnership = true;
                }
              ];
              authentication = pkgs.lib.mkOverride 10 ''
                local all       all     trust
                host  all       all     127.0.0.1/32 trust
                host  all       all     ::1/128      trust
                host  all       all     0.0.0.0/0    trust
              '';
              enableTCPIP = true;
            };
            services.redis.servers.pixelfed = {
              enable = true;
              bind = "0.0.0.0";
              port = 6379;
              settings.protected-mode = "no";
            };
          };
        };
      };

      components.pixelfed = {
        command = pkgs.writeShellScriptBin "start-pixelfed" ''
          cd ${pixelfed}
          exec ./artisan serve --host 0.0.0.0 --port 8080
        '';
        stateDir = "/var/lib/pixelfed";
        ports = [ "8080:8080" ];
        environment = pixelfedEnv;
        packages = [
          (pkgs.writeShellScriptBin "pixelfed-manage" ''
            cd ${pixelfed}
            exec ./artisan "$@"
          '')
          pkgs.coreutils
          pkgs.bash
        ];
        preStart = ''
          export PATH=$PATH:${pkgs.coreutils}/bin
          mkdir -p /run/pixelfed/cache /var/lib/pixelfed/storage

          # Initialize bootstrap cache required by Pixelfed.
          # These must be writable, so we symlink them into /run/pixelfed which is managed by systemd's RuntimeDirectory
          ln -sf ${pixelfed}/bootstrap-static/app.php /run/pixelfed/app.php
          ln -sf ${pixelfed}/bootstrap-static/packages.php /run/pixelfed/packages.php
          ln -sf ${pixelfed}/bootstrap-static/services.php /run/pixelfed/services.php

          if [ ! -d /var/lib/pixelfed/storage/app ]; then
            cp -r ${pixelfed}/storage-static/* /var/lib/pixelfed/storage/
            chmod -R +w /var/lib/pixelfed/storage
          fi

          cd ${pixelfed}

          while ! ${pkgs.postgresql}/bin/pg_isready -h $DB_HOST -U pixelfed; do
            echo "Waiting for postgres..."
            sleep 2
          done

          # Force migrate the database (mirrors `automaticMigrations = true` in nixos module).
          ./artisan migrate --force

          if [[ ! -f /var/lib/pixelfed/.initial-migration ]]; then
            touch /var/lib/pixelfed/.initial-migration
          fi

          [[ ! -f /var/lib/pixelfed/.passport-keys-generated ]] && ./artisan passport:keys && touch /var/lib/pixelfed/.passport-keys-generated

          ./artisan import:cities

          [[ ! -f /var/lib/pixelfed/.instance-actor-created ]] && ./artisan instance:actor && touch /var/lib/pixelfed/.instance-actor-created

          ./artisan route:cache
          ./artisan view:cache
        '';
      };

      runtimes = {
        container = {
          enable = true;
          composeFile = pkgs.replaceVars ./compose.yaml {
            coreutils = pkgs.coreutils;
            pixelfedManage = pkgs.writeShellScriptBin "pixelfed-manage" ''
              cd ${pixelfed}
              exec ./artisan "$@"
            '';
          };
        };
        nixos = {
          enable = true;
          extraComponents.pixelfed-extracomponents.nixosConfig = {
            networking.extraHosts = "127.0.0.1 pixelfed-extracomponents";
          };
          nixosConfig = {
            systemd.services.pixelfed = {
              serviceConfig = {
                # Ensures systemd creates /run/pixelfed with correct permissions for the dynamic user before preStart runs
                RuntimeDirectory = lib.mkForce "pixelfed";
              };
              after = [
                "postgresql.service"
                "redis-pixelfed.service"
              ];
              requires = [
                "postgresql.service"
                "redis-pixelfed.service"
              ];
            };
            systemd.services.pixelfed-worker = {
              description = lib.mkForce "Pixelfed Horizon Worker";
              wantedBy = [ "pixelfed.service" ];
              bindsTo = [ "pixelfed.service" ];
              after = [ "pixelfed.service" ];
              requires = [ "pixelfed.service" ];
              environment = lib.mkForce pixelfedEnv;
              serviceConfig = {
                DynamicUser = true;
                # Force both web and worker to use the same exact dynamic user/group.
                # Otherwise, systemd will create separate dynamic users, causing permission conflicts in the shared StateDirectory.
                User = lib.mkForce "pixelfed";
                Group = lib.mkForce "pixelfed";
                StateDirectory = lib.mkForce "pixelfed";
                RuntimeDirectory = lib.mkForce "pixelfed";
                ExecStart = pkgs.writeShellScript "start-pixelfed-worker" ''
                  cd /var/lib/pixelfed
                  # Worker must wait for the main service's preStart to finish copying static files to the state dir.
                  # Absolute path to sleep is required because systemd ExecStart environments lack PATH.
                  while [ ! -f /var/lib/pixelfed/storage/app/public/.gitignore ]; do ''${pkgs.coreutils}/bin/sleep 1; done
                  exec ${pixelfed}/artisan horizon
                '';
              };
            };
          };
        };
      };
    };

    test.services = {
      nixosConfig = {
        # Pixelfed's import:cities command during preStart requires significantly more memory and disk than the default VM
        virtualisation.memorySize = lib.mkForce 4096;
        virtualisation.diskSize = lib.mkForce 10240;
      };
      script = ''
        curl="curl --retry 40 --retry-max-time 600 --retry-all-errors"
        $curl --location http://localhost:8080 | grep -i "Pixelfed"
      '';
    };
  };
}
