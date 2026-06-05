{
  pkgs,
  apps,
  ...
}:

{
  apps.qlever = {
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
        command = pkgs.qlever-ui;
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
        packages = with pkgs; [
          qlever-ui
          subversion
        ];
        ports = [
          "8080:8080"
        ];
        after = [
          "qlever-server"
        ];
      };

      components.qlever-server = {
        configData."service-data" = {
          source = "${pkgs.qlever-olympics-rdf-data}/olympics.nt";
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
        command = pkgs.qlever-control;
        argv = [
          "--qleverfile"
          "/var/lib/qlever-server/Qleverfile"
          "start"
          "--run-in-foreground"
        ];
        packages = with pkgs; [
          curl
          qlever
          qlever-control
          unzip
        ];
        ports = [
          "7019:7019"
        ];
      };

      runtimes = {
        container = {
          enable = true;
          components.qlever-ui = {
            setup =
              # bash
              ''
                WORKDIR=/var/lib/qlever-ui

                # only copy db on first run so we don't overwrite it
                if [ ! -d "$WORKDIR/db" ]; then
                  rsync -a --no-owner --no-group --chmod=u=rwX,g=rwX,o=rX ${pkgs.qlever-ui}/opt/db "$WORKDIR"
                fi

                rsync -a --no-owner --no-group --chmod=u=rwX,go=rX --exclude='/db/' ${pkgs.qlever-ui}/opt/ "$WORKDIR"
              '';
            packages = with pkgs; [
              rsync # required by setup
            ];
          };

          components.qlever-server = {
            packages = with pkgs; [
              bash # required by qlever index
              coreutils # required by qlever index
            ];
          };
        };

        nixos = {
          enable = true;
          setup = apps.qlever.services.runtimes.container.components.qlever-ui.setup;
          packages = with pkgs; [
            rsync # required by setup
          ];
        };
      };
    };

    test.services = {
      nixosConfig.virtualisation.memorySize = 4096;
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
  };
}
