{
  lib,
  ...
}:
{
  options = {
    endpoints = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            options = {
              port = lib.mkOption {
                type = lib.types.port;
                description = "Port number of the endpoint.";
                example = 8000;
              };

              forwardedPort = lib.mkOption {
                internal = true;
                readOnly = true;
                type = lib.types.port;
                # Privileged ports (below 1024) can't be bound on the host by rootless
                # podman or QEMU user networking, so they are shifted by 20000:
                #
                # - shifted ports (20000-21023) are clear of the ports blocked by the
                #   browsers, the highest of which is 10080
                #   (https://fetch.spec.whatwg.org/#port-blocking)
                #
                # - shifted ports stay below the ephemeral port ranges used for outgoing
                #   connections, 32768-60999 on Linux
                #   (https://docs.kernel.org/networking/ip-sysctl.html, see
                #   `ip_local_port_range`) and 49152-65535 recommended by IANA
                #   (https://www.rfc-editor.org/rfc/rfc6335#section-6)
                #
                # - shifted ports are rarely used by applications, unlike for example
                #   8000 offset (80 -> 8080) which collides with common application ports
                default = if config.port < 1024 then 20000 + config.port else config.port;
                defaultText = lib.literalExpression "if port < 1024 then 20000 + port else port";
                description = ''
                  Host port forwarded to the endpoint `port` by the container and NixOS VM
                  runtimes. Privileged ports (below 1024) are shifted by 20000.
                '';
              };

              protocol = lib.mkOption {
                type = lib.types.enum [
                  "tcp"
                  "udp"
                ];
                default = "tcp";
                description = "Transport-level protocol of the endpoint.";
                example = lib.literalExpression ''"udp"'';
              };

              appProtocol = lib.mkOption {
                type = lib.types.str;
                default = "http";
                description = ''
                  Application-level protocol of the endpoint, such as `http`, `https`,
                  `websocket` or `postgresql`.
                '';
                example = lib.literalExpression ''"postgresql"'';
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Endpoints exposed to the users of the app, by name.

        All endpoints are forwarded to the host by the container and NixOS VM
        runtimes and opened in the firewall of deployed machines.
      '';
      example = lib.literalExpression ''
        {
          web.port = 8000;
        }
      '';
    };
  };
}
