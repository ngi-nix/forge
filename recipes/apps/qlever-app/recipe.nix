{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "qlever-app";
  displayName = "QLever";
  description = "Web-based user interface for QLever SPARQL engine.";
  usage = ''
    By default, the Olympics dataset is downloaded and indexed on startup.
    To use a different dataset, choose one from the [available use cases](https://docs.qlever.dev/use-cases) and update your `./Qleverfile` accordingly.

    Once indexing is complete, open the UI in your browser at `http://localhost:8000` and run the following query:

    ```sparql
    SELECT * WHERE { ?s ?p ?o } LIMIT 10
    ```

    If everything is working, results will appear below the input field.

    _Available in: container, nixos._
  '';

  links = {
    website = "https://github.com/ad-freiburg/qlever";
    source = "https://github.com/ad-freiburg/qlever";
  };

  ngi.grants = {
    Review = [
      "QLever-similarity"
    ];
  };

  services = {
    components.qlever-ui = {
      command = pkgs.mypkgs.qlever-ui;
      argv = [
        "--bind=0.0.0.0:8000"
      ];
      environment = {
        DJANGO_SETTINGS_MODULE = "qlever.settings";
        QLEVERUI_DATABASE_URL = "sqlite:////var/lib/qlever/db/qleverui.sqlite3";
      };
      preStart = ''
        qlever-ui-manage makemigrations --merge && qlever-ui-manage migrate
      '';
    };

    components.qlever-server = {
      configData."service-data" = {
        source = "${pkgs.mypkgs.qlever-olympics-rdf-data}/olympics.nt";
        path = "olympics.nt";
      };
      preStart = ''
        WORKDIR=/var/lib/qlever

        echo "Installing configuration files ..."
        install -D ${./Qleverfile} "$WORKDIR"/Qleverfile

        echo "Fetching and indexing data ..."
        install -D ''$XDG_CONFIG_HOME/olympics.nt "$WORKDIR"/olympics.nt
        qlever index --overwrite-existing
      '';
      command = pkgs.mypkgs.qlever-control;
      argv = [
        "--qleverfile"
        "/var/lib/qlever/Qleverfile"
        "start"
        "--run-in-foreground"
      ];
    };

    runtimes = {
      container = {
        enable = true;
        packages = with pkgs; [
          bash
          coreutils

          # UI
          mypkgs.qlever-ui
          rsync
          subversion

          # server
          curl
          mypkgs.qlever
          mypkgs.qlever-control
          unzip
        ];
        composeFile = ./compose.yaml;
        extraConfig = {
          WorkingDir = "/var/lib/qlever";
        };
        setup =
          # bash
          ''
            WORKDIR=/var/lib/qlever

            # only copy db on first run so we don't overwrite it
            if [ ! -d "$WORKDIR/db" ]; then
              rsync -a --chmod=u=rwX,g=rwX,o=rX ${pkgs.mypkgs.qlever-ui}/opt/db "$WORKDIR"
            fi

            rsync -a --chmod=u=rwX,go=rX --exclude='/db/' ${pkgs.mypkgs.qlever-ui}/opt/ "$WORKDIR"
          '';
      };

      nixos = {
        enable = true;
        setup = config.services.runtimes.container.setup;
        extraConfig = {
          systemd.services."qlever-app-setup" = {
            path = with pkgs; [
              rsync
            ];
            serviceConfig = {
              User = "qlever-ui";
              Group = "qlever-ui";
              DynamicUser = true;
              StateDirectory = [ "qlever" ];
              WorkingDirectory = "/var/lib/qlever";
            };
          };

          systemd.services."qlever-ui" = {
            path = with pkgs; [
              mypkgs.qlever-ui
              subversion
            ];
            serviceConfig = {
              User = "qlever-ui";
              Group = "qlever-ui";
              DynamicUser = true;
              StateDirectory = [ "qlever" ];
              WorkingDirectory = "/var/lib/qlever";
            };
            after = [
              "qlever-app-setup.service"
              "qlever-server.service"
            ];
            requires = [
              "qlever-app-setup.service"
              "qlever-server.service"
            ];
          };

          systemd.services."qlever-server" = {
            path = with pkgs; [
              curl
              mypkgs.qlever
              mypkgs.qlever-control
              unzip
            ];
            serviceConfig = {
              User = "qlever-ui";
              Group = "qlever-ui";
              DynamicUser = true;
              StateDirectory = [ "qlever" ];
              WorkingDirectory = "/var/lib/qlever";
            };
          };
        };
        vm = {
          forwardPorts = [
            "8000:8000"
          ];
        };
      };
    };
  };

  test = {
    script = ''
      curl="curl --retry 20 --retry-max-time 120 --retry-all-errors"

      # UI accessible
      $curl --location localhost:8000 | grep -i "qlever"

      # query indexed data
      result=$($curl -s localhost:7019 \
        -H "Accept: text/tab-separated-values" \
        --data-urlencode "query=SELECT * WHERE { ?s ?p ?o } LIMIT 10")
      echo "$result"
      test "$(printf '%s\n' "$result" | wc -l)" -eq 11
    '';
  };
}
