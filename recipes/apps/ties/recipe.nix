{
  config,
  pkgs,
  ...
}:
let
  recipe = config.apps.ties;
  adminUsername = "admin";
  adminPassword = "Admin@1234";
  listenPort = "8080";
in
{
  apps.ties = {
    displayName = "Ties";
    description = "A federated network to bookmark, organize, share and discover good web pages.";
    usage = ''
      Ties is a personal and federated space for keeping track of the web pages you care about. Use it to build collections of interesting pages, browse and search bookmarks, share curated lists with others, and discover pages through people whose taste you trust. 

      Ties is designed around the idea that finding good websites is valuable and that sharing carefully curated collections can help others discover them. You can follow other users, explore their collections, and build a network of trusted users whose bookmarks become part of your search and discovery space.

      #### Getting Started 
      Ties requires a PostgreSQL database. There are several ways to run the server: 

      - **Container:** Run Ties together with a PostgreSQL service using the container runtime. 
      - **NixOS/VM:** Run Ties as a NixOS service with PostgreSQL configured by the VM runtime. 
      - **Local binary:** Use the Ties binary directly with an existing PostgreSQL instance. 

      For instructions on starting each runtime, click the `Run` button in the top-right corner of this page.

      If you already have PostgreSQL running locally, you can start Ties directly with: 

      ```bash 
      ties start \ 
        --database-url <pg-socket> \ 
        --base-url http://localhost:${listenPort} \ 
        --listen localhost:${listenPort}
      ```

      Once Ties is running, open the web interface: 

      [http://localhost:${listenPort}](http://localhost:${listenPort}) 

      Sign in using the administrator credentials configured for this instance: 

      - **Username:** `${adminUsername}` 
      - **Password:** `${adminPassword}`

      #### Discovery

      Ties provides several ways to discover new web pages:

      - Browse collections shared by other users.
      - Follow users whose interests and taste you enjoy.
      - Search through bookmarks from users you trust.
      - Expand your search to include users trusted by people you already trust.

      You can also annotate, highlight, and discuss web pages with other users.

      #### Sharing

      Collections can be shared with other Ties users or exposed publicly on the web. This makes Ties useful both as a personal bookmark manager and as a way to curate and publish reading lists or collections of interesting websites.

      #### Browser Compatibility 

      When running a self-hosted instance locally, some browsers may not work correctly with the default configuration. Ties uses secure cookies for authentication, but browsers differ in whether they allow secure cookies when accessing an application over `http://localhost`. 

      If you are unable to log in, try accessing the instance with a browser that supports secure cookies on `localhost` eg. Chromium.

      #### Current Limitations

      Ties is currently in an exploratory alpha stage, so features and behavior may change between releases.

      Only single-user instances are currently supported. The project also recommends treating all data as publicly available, including bookmarks in private lists.

      For more information, see the [Ties documentation](${recipe.links.docs}).
    '';

    links = {
      website = "https://demo.ties.pub";
      source = "https://github.com/raffomania/ties";
      docs = "https://github.com/raffomania/ties/blob/main/doc/index.md";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Ties"
      ];
    };

    programs = {
      mainPackage = pkgs.ties;
      packages = [ pkgs.ties ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    services = {
      components.ties = {
        process = {
          command = pkgs.ties;
          ports = [ "${listenPort}:${listenPort}" ];
          argv = [
            "start"
            "--database-url"
            "postgresql://postgres@database/postgres"
            "--base-url"
            "http://localhost:${listenPort}"
            "--listen"
            "0.0.0.0:${listenPort}" # accept connections from outside the container
            "--admin_username"
            "${adminUsername}"
            "--admin_password"
            "${adminPassword}"
          ];
        };

        resources.database.nixosConfig = {
          services.postgresql.enable = true;
        };
      };

      runtimes.container = {
        enable = true;
        resources.database.nixosConfig = {
          services.postgresql.enableTCPIP = true;
          services.postgresql.authentication = ''
            host all all 0.0.0.0/0 trust
            host all all ::0/0 trust
          '';
        };
      };

      runtimes.nixos = {
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

    test.services.script = ''
      # wait for ties to become ready
      for i in $(seq 1 10); do
        if curl -fs "http://localhost:${listenPort}"; then
          exit 0
        fi
        sleep 3
      done
      echo "Ties did not become ready in time"
      exit 1
    '';

  };
}
