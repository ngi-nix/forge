{
  forge-lib,
  config,
  pkgs,
  lib,
  ...
}:
let
  app = config.apps.forgejo;
  endpoints = app.services.components.forgejo.endpoints;
  stateDir = app.services.components.forgejo.process.stateDir;
  customDir = "${stateDir}/custom";

  inherit (app.parameters)
    httpPort
    sshPort
    hostname
    adminUser
    adminPassword
    ;

  # An empty `publicUrl` parameter gives an address with the host name and the forwarded port.
  # Thus a changed `hostname` or `httpPort` parameter also changes the address.
  publicUrl =
    if app.parameters.publicUrl == "" then
      "http://${hostname}:${toString endpoints.web.forwardedPort}/"
    else
      app.parameters.publicUrl;

  forgejo = pkgs.pkgsOriginal.forgejo;
  forgejoExe = lib.getExe forgejo;

  settingsFormat = pkgs.formats.ini { };
  settings = {
    DEFAULT = {
      RUN_MODE = "prod";
      WORK_PATH = stateDir;
    };
    database = {
      DB_TYPE = "sqlite3";
      PATH = "${stateDir}/data/forgejo.db";
    };
    repository.ROOT = "${stateDir}/repositories";
    server = {
      DOMAIN = hostname;
      HTTP_PORT = httpPort;
      ROOT_URL = publicUrl;
      # Use the SSH server of Forgejo, not OpenSSH.
      START_SSH_SERVER = true;
      SSH_DOMAIN = hostname;
      SSH_LISTEN_PORT = sshPort;
      # Port in the clone URLs.
      SSH_PORT = endpoints.ssh.forwardedPort;
      BUILTIN_SSH_SERVER_USER = "git";
    };
    session.COOKIE_NAME = "session";
    security = {
      INSTALL_LOCK = true;
      SECRET_KEY_URI = "file:${customDir}/conf/secret_key";
      INTERNAL_TOKEN_URI = "file:${customDir}/conf/internal_token";
    };
    oauth2.JWT_SECRET_URI = "file:${customDir}/conf/jwt_secret";
    service.DISABLE_REGISTRATION = true;
  };
in
{
  pkgs.forgejo = {
    build.builders.identity = {
      enable = true;
      derivation = forgejo;
    };
  };

  apps.forgejo = {
    displayName = "Forgejo";
    description = "Self-hosted software forge.";
    longDescription = ''
      Forgejo is a software forge. It hosts Git repositories and gives code review, issue tracking, wikis, package registries and CI with Forgejo Actions.
      Forgejo is a community fork of Gitea.
    '';
    usage = ''
      The web interface is available on [${publicUrl}](${publicUrl}).
      Log in with the user `${adminUser}` and the password `${adminPassword}`. This user is an administrator.

      Git over SSH is available on the port `${toString endpoints.ssh.forwardedPort}`.
      Add your SSH public key in the user settings, then clone a repository:

      ```bash
      git clone ssh://git@${hostname}:${toString endpoints.ssh.forwardedPort}/${adminUser}/<repository>.git
      ```

      This configuration is for evaluation only. Before you use Forgejo in production, change the `adminPassword`, `hostname` and `publicUrl` parameters and configure TLS, for example with a reverse proxy.

      > [!CAUTION]
      > In default configuration, the password of the administrator user is `${adminPassword}`.
      > It is stored in the Nix store, which is world-readable.
      > After the first login, change the password in the web interface.
    '';

    categories = with forge-lib.categories; [ Development ];

    icon = ./icon.svg;

    parameters = {
      httpPort = {
        value = 3000;
        description = "Port of the web interface and HTTP Git access.";
      };
      sshPort = {
        value = 2222;
        description = "Port of the SSH server for Git access.";
      };
      hostname = {
        value = "localhost";
        description = "Host name of the server. Forgejo uses it in the SSH clone URLs.";
      };
      publicUrl = {
        value = "";
        description = "Public address of the web interface, for example the address of a reverse proxy. Forgejo uses it in links and HTTP clone URLs. If empty, it is `http://` with the host name and the port of the web interface.";
      };
      adminUser = {
        value = "demo";
        description = "Name of the administrator user. Forgejo does not accept the name `admin`.";
      };
      adminPassword = {
        value = "demo1234";
        description = "Initial password of the administrator user. The first start sets this password. Forgejo requires at least 8 characters.";
      };
    };

    links = {
      website = "https://forgejo.org";
      docs = "https://forgejo.org/docs/latest/";
      source = "https://codeberg.org/forgejo/forgejo";
    };

    ngi.grants = {
      Commons = [ "Forgejo-workflow" ];
      Entrust = [
        "Forgejo"
        "Federated-Forgejo"
      ];
    };

    services = {
      components.forgejo = {
        process = {
          command = forgejo;
          argv = [ "web" ];
          environment = {
            HOME = stateDir;
            FORGEJO_WORK_DIR = stateDir;
            FORGEJO_CUSTOM = customDir;
          };
          configData."app.ini" = {
            source = settingsFormat.generate "app.ini" settings;
            path = "app.ini";
          };
          # Forgejo reads the configuration from `$FORGEJO_CUSTOM/conf/app.ini`.
          # It must be a file that Forgejo can write.
          preStart = ''
            umask 027
            mkdir --parents ${customDir}/conf ${stateDir}/data ${stateDir}/log

            for secret in SECRET_KEY INTERNAL_TOKEN JWT_SECRET; do
              file=${customDir}/conf/''${secret,,}
              if [ ! -s "$file" ]; then
                (umask 077; ${forgejoExe} generate secret "$secret" > "$file")
              fi
            done

            install --mode=0640 "$XDG_CONFIG_HOME/app.ini" ${customDir}/conf/app.ini

            ${forgejoExe} migrate
            ${forgejoExe} admin regenerate hooks

            # Make the administrator at the first start. Later starts do not change the user,
            # thus a password change in the web interface stays.
            if ! ${forgejoExe} admin user list | ${lib.getExe pkgs.gnugrep} -qw ${lib.escapeShellArg adminUser}; then
              ${forgejoExe} admin user create --admin --username ${lib.escapeShellArg adminUser} \
                --password ${lib.escapeShellArg adminPassword} --email ${lib.escapeShellArg "${adminUser}@${hostname}"} \
                --must-change-password=false
            fi
          '';
          # The Git hooks of Forgejo use `bash` and `coreutils`.
          packages = [
            forgejo
            pkgs.bash
            pkgs.coreutils
            pkgs.git
            pkgs.gnupg
          ];
        };
        endpoints = {
          web.port = httpPort;
          ssh = {
            port = sshPort;
            appProtocol = "ssh";
          };
        };
        healthcheck = {
          enable = true;
          test = [
            "curl"
            "-fs"
            "http://localhost:${toString httpPort}/api/healthz"
          ];
          packages = [ pkgs.curl ];
          startPeriod = "30s";
        };
      };

      runtimes = {
        container.enable = true;
        nixos.enable = true;
      };
    };

    test.services = {
      packages = [
        pkgs.git
        pkgs.openssh
      ];
      script = ''
        cd "$(mktemp -d)"
        curl="curl --fail --silent --retry 10 --retry-max-time 120 --retry-all-errors"
        api=localhost:${toString httpPort}/api/v1
        auth=${lib.escapeShellArg "${adminUser}:${adminPassword}"}

        # The web interface responds and the administrator can log in.
        $curl localhost:${toString httpPort}/user/login | grep -i "forgejo" >/dev/null
        $curl --user "$auth" $api/user | grep '"login":"${adminUser}"' >/dev/null

        # Make a repository and clone it over SSH.
        ssh-keygen -t ed25519 -N "" -f ./id_ed25519
        $curl --user "$auth" -H "Content-Type: application/json" \
          -d "{\"title\": \"test\", \"key\": \"$(cat ./id_ed25519.pub)\"}" $api/user/keys >/dev/null
        $curl --user "$auth" -H "Content-Type: application/json" \
          -d '{"name": "test", "auto_init": true}' $api/user/repos >/dev/null
        GIT_SSH_COMMAND="ssh -i ./id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
          git clone ssh://git@localhost:${toString sshPort}/${adminUser}/test.git
        test -f test/README.md
      '';
    };
  };
}
