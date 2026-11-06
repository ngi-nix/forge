{
  config,
  forgeConfig,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.livebook;
  usageSnippets = forgeConfig.forge.snippets.usage app;

  port = "8080";
  caCertFile = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  baseEnv = {
    SSL_CERT_FILE = caCertFile;
    LIVEBOOK_CACERTFILE = caCertFile;
    ELIXIR_ERL_OPTIONS = "+fnu";
    LC_ALL = "C.UTF-8";
    LANG = "C.UTF-8";
  };

  exportBaseEnv = lib.concatLines (
    lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") baseEnv
  );

  runtimePackages = with pkgs; [
    livebook
    coreutils
    bash
    cacert
    glibc
  ];

  fhsCompatSetup = ''
    mkdir -p /etc/ssl/certs /lib64
    ln -sf ${caCertFile} /etc/ssl/certs/ca-certificates.crt
    ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
  '';
in
{
  pkgs.livebook = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.livebook;
    };
  };

  apps.livebook = {
    displayName = "Livebook";
    description = "Automate code and data workflows with interactive Elixir notebooks.";
    longDescription = ''
      Livebook is a web application for writing interactive and collaborative code notebooks for Elixir, Erlang and Python programming languages.

      It supports rich, interactive outputs, distributed execution, step-by-step debugging, and seamless integration with the Erlang VM.
    '';
    usage = ''
      First, ${usageSnippets.run-container} or ${usageSnippets.run-nixos}.

      ##### Web Interface

      Open the [web interface](http://localhost:${port}) in your browser.
      Authentication token is disabled by default for ease of local use.

      ##### Managing Livebook

      Livebook stores configuration and notebook data in `/var/lib/livebook`.

      ##### Example Notebook

      Livebook supports multi-language notebooks with Elixir, Erlang, and Python.

      To run Python code in Livebook, install the `pythonx` package in your notebook setup:

      <!-- NOTE: 4 ticks because markdown itself will contain 3 ticks this is an official supported feature in markdown -->
      ````markdown file ${app.data.exampleNotebook.name}
      ${app.data.exampleNotebook}
      ````

      See [learn](http://localhost:${port}/learn) to see Livebook's full tutorial.
    '';

    categories = with lib.categories; [ Development ];

    links = {
      website = "https://livebook.dev";
      docs = "https://livebook.hexdocs.pm/readme.html";
      source = "https://github.com/livebook-dev/livebook";
    };

    ngi.grants = {
      Commons = [
        "Livebook-Python"
      ];
    };

    icon = ./icon.svg;

    data = {
      exampleNotebook = ./example_notebook.livemd;
      testNotebook = ./test_notebook.livemd;
      testEval = ./test_eval.exs;
    };

    services = {
      components.livebook = {
        process = {
          command = pkgs.livebook;
          argv = [ "start" ];
          user = "root";
          environment = baseEnv // {
            HOME = "/var/lib/livebook";
            RELEASE_TMP = "/var/lib/livebook/tmp";
            RELEASE_COOKIE = "livebook_cookie";
            LIVEBOOK_DATA_PATH = "/var/lib/livebook/data";
            LIVEBOOK_HOME = "/var/lib/livebook";
            LIVEBOOK_IP = "0.0.0.0";
            LIVEBOOK_PORT = port;
            LIVEBOOK_TOKEN_ENABLED = "false";
          };
          preStart = ''
            mkdir -p /var/lib/livebook/{tmp,data}
            ${fhsCompatSetup}
          '';
          ports = [
            "${port}:${port}"
          ];
        };

        healthcheck = {
          enable = true;
          test = [
            (lib.getExe pkgs.curl)
            "-fs"
            "http://localhost:${port}/public/health"
          ];
          packages = [ pkgs.curl ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "10s";
          retries = 10;
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.livebook = {
            packages = runtimePackages;
          };
        };

        nixos = {
          enable = true;
          packages = runtimePackages;
        };
      };
    };

    test.services = {
      # NOTE: pythonx Elixir dependency is required to run python tests
      # But pythonx is not trivial to be fetched with a fixed output derivation and kept uptodate.
      # And our CI doesn't allow relaxing nix sandbox, for this reason python execution is not tested.
      # sandbox = false;
      packages = [
        pkgs.curl
      ]
      ++ runtimePackages;
      script = /* bash */ ''
        curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"

        $curl -fs "localhost:${port}/public/health" | grep '"application":"livebook"'
        $curl -fs "localhost:${port}" | grep '<title>'

        # Create a new notebook and verify it is accessible and can be exported
        SESSION_URL=$($curl -s -i "localhost:${port}/new" | tr -d '\r' | awk -F': ' '/^location:/{print $2}')
        $curl -fs "localhost:${port}$SESSION_URL" | grep 'Untitled notebook - Livebook'
        $curl -fs "localhost:${port}$SESSION_URL/download/export/livemd" | grep '# Untitled notebook'

        # Set up SSL certificates and glibc dynamic loader for pythonx/uv
        ${fhsCompatSetup}

        ${exportBaseEnv}
        export HOME="''${TMPDIR:-/tmp}/livebook-test-home"
        export RELEASE_TMP="''${TMPDIR:-/tmp}/livebook-release-tmp"
        mkdir -p "$HOME" "$RELEASE_TMP"

        # Shift Erlang distribution port range so evaluator and child runtime nodes don't collide with the running service (13825)
        export ERL_AFLAGS="-kernel inet_dist_listen_min 13826 inet_dist_listen_max 13835"

        # Copy the test notebook with Elixir and Erlang cells
        cp ${app.data.testNotebook.path} "$HOME/${app.data.testNotebook.name}"

        # Run the notebook in Livebook and verify execution of Elixir and Erlang cells
        livebook eval 'Code.eval_file("${app.data.testEval.path}")'
      '';
    };
  };
}
