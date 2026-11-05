{
  lib,
  ...
}:
let
  # List of ports above 1024 blocked by the web browsers
  # (https://fetch.spec.whatwg.org/#port-blocking).
  browserBlockedPorts = [
    1719
    1720
    1723
    2049
    3659
    4045
    4190
    5060
    5061
    6000
    6566
    6665
    6666
    6667
    6668
    6669
    6679
    6697
    10080
  ];

  # First port, starting from `port`, which is not blocked by the web browsers.
  nextUnblockedPort =
    port: if lib.elem port browserBlockedPorts then nextUnblockedPort (port + 1) else port;
in
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
                type = lib.types.addCheck lib.types.port (port: !lib.elem port browserBlockedPorts) // {
                  description = "16 bit unsigned integer, not blocked by the web browsers";
                };
                # Ports blocked by the browsers (eg. 6000, or 80 -> 10080 when shifted)
                # are moved to the next unblocked port (eg. 6001 or 10081),
                # so they can be opened in a browser.
                #
                # Privileged ports (below 1024) can't be bound on the host by rootless
                # podman or QEMU user networking, so they are shifted by 10000:
                #
                # - shifted ports stay below the ephemeral port ranges used for outgoing
                #   connections, 32768-60999 on Linux
                #   (https://docs.kernel.org/networking/ip-sysctl.html, see
                #   `ip_local_port_range`) and 49152-65535 recommended by IANA
                #   (https://www.rfc-editor.org/rfc/rfc6335#section-6)
                #
                # - shifted ports are rarely used by applications, unlike for example
                #   8000 offset (80 -> 8080) which collides with common application ports
                default = nextUnblockedPort (if config.port < 1024 then 10000 + config.port else config.port);
                defaultText = lib.literalExpression ''
                  # Next port not blocked by the browsers, starting from:
                  nextUnblockedPort (if port < 1024 then 10000 + port else port)
                '';
                description = ''
                  Host port forwarded to the endpoint `port` by the container and NixOS VM
                  runtimes. Privileged ports (below 1024) are shifted by 10000 by default.
                  Ports blocked by the web browsers can't be used and are skipped by default
                  (eg. `80` is forwarded to `10081`, because `10080` is blocked).
                '';
                example = 8080;
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
      '';
      example = lib.literalExpression ''
        {
          web.port = 8000;
        }
      '';
    };
  };
}
