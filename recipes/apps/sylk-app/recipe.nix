{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "sylk-app";
  displayName = "Sylk";
  description = "Secure multiparty videoconferencing client and server.";

  usage = ''
    Sylk is a complete suite for multiparty videoconferencing.

    #### Sylk Client
    Desktop WebRTC client for joining video conferences.

    _Available in: shell._

    #### SylkServer
    SIP/XMPP/WebRTC application server for hosting conferences.

    Ports:
    - SIP: 5060
    - Web: 10888
    - HTTPS: 443

    _Available in: container, nixos._

    #### Usage

    The client connects by default to the free SIP2SIP service.
    For self-hosted servers, configure the server URL in the client settings.
  '';

  links = {
    source = "https://github.com/AGProjects";
    website = "https://sylkserver.com";
    docs = "https://sylkserver.com/documentation";
  };

  ngi.grants = {
    Commons = [
      "SylkContact"
    ];
    Review = [
      "SylkChat"
      "SylkClient"
      "SylkMobile"
      "sylkRTC"
    ];
  };

  programs = {
    packages = [ pkgs.sylk ];
    runtimes.shell.enable = true;
  };

  services = {
    components = {
      sylkserver = {
        command = pkgs.sylkserver;
        argv = [
          "--no-fork"
          "--config-dir"
          "/var/lib/sylkserver/config"
        ];
        configData = {
          "sylkserver/config.ini" = {
            source = ./config.ini;
            path = "sylkserver/config.ini";
          };
          "sylkserver/conference.ini" = {
            source = ./conference.ini;
            path = "sylkserver/conference.ini";
          };
          "sylkserver/auth.ini" = {
            source = ./auth.ini;
            path = "sylkserver/auth.ini";
          };
          "sylkserver/playback.ini" = {
            source = ./playback.ini;
            path = "sylkserver/playback.ini";
          };
          "sylkserver/webrtcgateway.ini" = {
            source = ./webrtcgateway.ini;
            path = "sylkserver/webrtcgateway.ini";
          };
          "sylkserver/xmppgateway.ini" = {
            source = ./xmppgateway.ini;
            path = "sylkserver/xmppgateway.ini";
          };
          "sylkserver/ircconference.ini" = {
            source = ./ircconference.ini;
            path = "sylkserver/ircconference.ini";
          };
        };
        preStart = ''
          echo "Installing configuration files ..."
          ln -sf ''$XDG_CONFIG_HOME/sylkserver /var/lib/sylkserver/config
          ln -sf "${pkgs.sylkserver}/share/sylkserver" /etc/sylkserver

          cat > /etc/default/sylkserver <<-EOF
          RUN_SYLKSERVER=yes
          EOF
        '';
      };

      sylk-web = {
        command = pkgs.mypkgs.sylk-web;
      };
    };

    runtimes = {
      container = {
        enable = true;
        packages = [
          pkgs.sylkserver
          pkgs.mypkgs.sylk-web
        ];
        composeFile = ./compose.yaml;
      };

      nixos = {
        enable = true;
        packages = [
          pkgs.sylkserver
          pkgs.mypkgs.sylk-web
        ];
        extraConfig = {
          systemd.services.sylkserver = {
            serviceConfig = {
              StateDirectory = [ "sylkserver" ];
            };
          };
        };
        vm.forwardPorts = [
          # Web
          "10888:10888"
          # SIP
          "5060:5060"
          "5061:5061"
        ];
      };
    };
  };

  test.script = ''
    curl="curl --retry 8 --retry-max-time 120 --retry-all-errors"

    $curl localhost:10888 | grep -qi "sylk"
  '';
}
