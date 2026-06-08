{
  pkgs,
  ...
}:

{
  apps.rotonda = {
    displayName = "Rotonda";
    description = "Composable and programmable BGP routing engine.";
    usage = ''
      Rotonda collects routing information from BGP and BMP sessions into an
      in-memory Routing Information Base (RIB), queryable via an HTTP/JSON API.

      #### HTTP API

      Query the routing information base

      ```
      curl http://localhost:8080/
      ```

      #### BMP sessions

      Rotonda listens for BMP (BGP Monitoring Protocol) connections on port 11019.
      Point your BMP-capable router to this address to start collecting routes.

      #### BGP sessions

      Add BGP peers to `rotonda.conf` under `[units.bgp-in]` to accept BGP sessions.
    '';

    links = {
      website = "https://www.nlnetlabs.nl/projects/routing/rotonda";
      docs = "https://rotonda.docs.nlnetlabs.nl";
      source = "https://github.com/NLnetLabs/rotonda";
    };

    ngi.grants = {
      Entrust = [
        "Rotonda"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.rotonda
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    services = {
      components.rotonda = {
        command = pkgs.rotonda;
        argv = [
          "-c"
          "${./rotonda.conf}"
        ];
        ports = [
          "8080:8080"
          "11019:11019"
        ];
      };

      runtimes = {
        container = {
          enable = true;
          components.rotonda.packages = [
            pkgs.bash
            pkgs.coreutils
            pkgs.rotonda
          ];
        };

        nixos = {
          enable = true;
          packages = [ pkgs.rotonda ];
        };
      };
    };

    test.services = {
      packages = [
        pkgs.netcat
      ];
      script = ''
        curl -f --retry 10 --retry-max-time 120 --retry-all-errors \
          http://localhost:8080/

        nc -z localhost 11019
      '';
    };
  };
}
