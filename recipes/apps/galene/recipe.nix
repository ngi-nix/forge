{
  forge-lib,
  lib,
  config,
  pkgs,
  ...
}:
let
  app = config.apps.galene;
  inherit (app.services.components.galene) endpoints;
  inherit (app.services.components.galene.process) stateDir;
  inherit (app.parameters)
    port
    turnPort
    turnAddress
    operatorPassword
    ;

  galene = pkgs.pkgsOriginal.galene;

  webUrl = "https://localhost:${toString endpoints.https.forwardedPort}";

  # Directory with the group definitions.
  # Galene reads one JSON file for each group.
  groupsDir = pkgs.writeTextDir "demo.json" (
    builtins.toJSON {
      description = "Demo group";
      public = true;
      users.demo = {
        password = operatorPassword;
        permissions = "op";
      };
    }
  );
in
{
  pkgs.galene = {
    build.builders.identity = {
      enable = true;
      derivation = galene;
    };
  };

  apps.galene = {
    displayName = "Galene";
    description = "Videoconference server that is easy to deploy and needs few server resources.";
    longDescription = ''
      Galene is a videoconference server for lectures, meetings and conferences.
      It supports video, audio, screen sharing, text chat and recording.
      Users join a group in the web browser, without a separate client program.
      Galene has a built-in TURN server, thus clients behind NAT can connect.
    '';
    usage = ''
      Open the group `demo` on [${webUrl}/group/demo/](${webUrl}/group/demo/).
      Galene uses a self-signed TLS certificate, thus the web browser shows a security warning.
      Log in with the user `demo` and the password `${operatorPassword}`. This user is an operator of the group.

      The web browsers send audio and video through the built-in TURN server on the address `${turnAddress}` and the port `${toString endpoints.turn.forwardedPort}` (UDP and TCP).

      This configuration is for evaluation only. Before you use Galene in production, change the `operatorPassword` parameter, set the `turnAddress` parameter to the public IPv4 address of the server and configure a TLS certificate.
    '';

    categories = with forge-lib.categories; [ VideoConference ];

    icon = ./icon.svg;

    parameters = {
      port = {
        value = 8443;
        description = "Port of the HTTPS web interface.";
      };
      turnPort = {
        value = 1194;
        description = "UDP and TCP port of the built-in TURN server. The host must forward the same port number to the server.";
      };
      turnAddress = {
        value = "127.0.0.1";
        description = "Public IPv4 address of the built-in TURN server. The web browsers send audio and video to this address.";
      };
      operatorPassword = {
        value = "demo";
        description = "Password of the `demo` operator user in the `demo` group.";
      };
    };

    links = {
      website = "https://galene.org";
      source = "https://github.com/jech/galene";
      docs = "https://galene.org/galene-install.html";
    };

    ngi.grants = {
      Core = [ "Galene" ];
      Commons = [ "Galene-UX" ];
    };

    services = {
      components.galene = {
        process = {
          command = galene;
          argv = [
            "-http"
            ":${toString port}"
            # Galene listens on all addresses and tells the clients to use this address.
            "-turn"
            "${turnAddress}:${toString turnPort}"
            # Galene creates a self-signed TLS certificate in this directory.
            "-data"
            "${stateDir}/data"
            "-groups"
            "${groupsDir}"
            "-recordings"
            "${stateDir}/recordings"
            "-static"
            "${galene.static}/static"
          ];
          preStart = ''
            mkdir --parents ${stateDir}/data ${stateDir}/recordings
          '';
          packages = [ pkgs.coreutils ];
        };
        endpoints = {
          https = {
            inherit port;
            appProtocol = "https";
          };
          turn = {
            port = turnPort;
            protocol = "udp";
            appProtocol = "turn";
          };
          turn-tcp = {
            port = turnPort;
            appProtocol = "turn";
          };
        };
        healthcheck = {
          enable = true;
          test = [
            "${lib.getExe pkgs.curl}"
            "--fail"
            "--silent"
            "--insecure"
            "--output"
            "/dev/null"
            "https://localhost:${toString port}/"
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

    test.services.script = ''
      curl="curl --fail --silent --insecure --retry 10 --retry-max-time 120 --retry-all-errors"
      url="https://localhost:${toString port}"

      # The web interface and the demo group are available.
      $curl $url/ | grep "<title>Gal" >/dev/null
      $curl $url/public-groups.json | grep '"demo"' >/dev/null
      $curl $url/group/demo/.status | grep '"name":"demo"' >/dev/null

      # The built-in TURN server listens on the TCP port.
      curl --silent --max-time 5 telnet://localhost:${toString turnPort} </dev/null || [ $? -eq 28 ]
    '';
  };
}
