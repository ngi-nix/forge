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

    Once indexing is complete, open the UI in your browser at [http://localhost:8080](http://localhost:8080) and run the following query:

    ```sparql
    SELECT * WHERE { ?s ?p ?o } LIMIT 10
    ```

    If everything is working, results will appear below the input field.

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
        "--bind=0.0.0.0:8080"
      ];
      environment = {
        DJANGO_SETTINGS_MODULE = "qlever.settings";
        QLEVERUI_DATABASE_URL = "sqlite:////var/lib/qlever-ui/db/qleverui.sqlite3";
      };
      preStart = ''
        qlever-ui-manage makemigrations --merge && qlever-ui-manage migrate
      '';
      ports = [
        "8080:8080"
      ];
      after = [
        "qlever-server"
      ];
    };

    components.qlever-server = {
      configData."service-data" = {
        source = "${pkgs.mypkgs.qlever-olympics-rdf-data}/olympics.nt";
        path = "olympics.nt";
      };
      preStart = ''
        WORKDIR=/var/lib/qlever-server

        echo "Installing configuration files ..."
        install -D ${./Qleverfile} "$WORKDIR"/Qleverfile

        echo "Fetching and indexing data ..."
        install -D ''$XDG_CONFIG_HOME/olympics.nt "$WORKDIR"/olympics.nt
        qlever index --overwrite-existing
      '';
      command = pkgs.mypkgs.qlever-control;
      argv = [
        "--qleverfile"
        "/var/lib/qlever-server/Qleverfile"
        "start"
        "--run-in-foreground"
      ];
      ports = [
        "7019:7019"
      ];
    };

    runtimes = {
      container = {
        enable = true;
        components.qlever-ui = {
          packages = with pkgs; [
            mypkgs.qlever-ui
            rsync
            subversion
          ];
          imageConfig = {
            WorkingDir = "/var/lib/qlever-ui";
          };
          setup =
            # bash
            ''
              WORKDIR=/var/lib/qlever-ui

              # only copy db on first run so we don't overwrite it
              if [ ! -d "$WORKDIR/db" ]; then
                rsync -a --chmod=u=rwX,g=rwX,o=rX ${pkgs.mypkgs.qlever-ui}/opt/db "$WORKDIR"
              fi

              rsync -a --chmod=u=rwX,go=rX --exclude='/db/' ${pkgs.mypkgs.qlever-ui}/opt/ "$WORKDIR"
            '';
        };
        components.qlever-server = {
          packages = with pkgs; [
            bash
            coreutils
            curl
            mypkgs.qlever
            mypkgs.qlever-control
          ];
          imageConfig = {
            WorkingDir = "/var/lib/qlever-server";
          };
        };
      };

      nixos = {
        enable = true;
        setup = config.services.runtimes.container.components.qlever-ui.setup;
        nixosConfig = {
          systemd.services."qlever-app-setup" = {
            path = with pkgs; [
              rsync
            ];
            serviceConfig = {
              DynamicUser = true;
              StateDirectory = [ "qlever-ui" ];
              WorkingDirectory = "/var/lib/qlever-ui";
            };
          };

          systemd.services."qlever-ui" = {
            path = with pkgs; [
              mypkgs.qlever-ui
              subversion
            ];
            serviceConfig = {
              DynamicUser = true;
              StateDirectory = [ "qlever-ui" ];
              WorkingDirectory = "/var/lib/qlever-ui";
            };
          };

          systemd.services."qlever-server" = {
            path = with pkgs; [
              curl
              mypkgs.qlever
              mypkgs.qlever-control
              unzip
            ];
            serviceConfig = {
              DynamicUser = true;
              StateDirectory = [ "qlever-server" ];
              WorkingDirectory = "/var/lib/qlever-server";
            };
          };
        };
      };
    };
  };

  test = {
    script = ''
      curl="curl --retry 40 --retry-max-time 240 --retry-all-errors"

      sleep 30

      # UI accessible
      $curl --location localhost:8080 | grep -i "qlever"

      sleep 30

      # query indexed data
      result=$($curl -s localhost:7019 \
        -H "Accept: text/tab-separated-values" \
        --data-urlencode "query=SELECT * WHERE { ?s ?p ?o } LIMIT 10")
      echo "$result"
      test "$(printf '%s\n' "$result" | wc -l)" -eq 11
    '';
  };
}
