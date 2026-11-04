{
  lib,
  ...
}:
let
  # Ports blocked by the web browsers
  # (https://fetch.spec.whatwg.org/#port-blocking).
  browserBlockedPorts = [
    0
    1
    7
    9
    11
    13
    15
    17
    19
    20
    21
    22
    23
    25
    37
    42
    43
    53
    69
    77
    79
    87
    95
    101
    102
    103
    104
    109
    110
    111
    113
    115
    117
    119
    123
    135
    137
    139
    143
    161
    179
    389
    427
    465
    512
    513
    514
    515
    526
    530
    531
    532
    540
    548
    554
    556
    563
    587
    601
    636
    989
    990
    993
    995
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
                type = lib.types.port;
                # Privileged ports (below 1024) can't be bound on the host by rootless
                # podman or QEMU user networking, so they are shifted by 10000:
                #
                # - shifted ports blocked by the browsers (eg. 80 -> 10080) are moved
                #   to the next unblocked port (eg. 10081), so they can be opened in
                #   a browser
                #
                # - shifted ports stay below the ephemeral port ranges used for outgoing
                #   connections, 32768-60999 on Linux
                #   (https://docs.kernel.org/networking/ip-sysctl.html, see
                #   `ip_local_port_range`) and 49152-65535 recommended by IANA
                #   (https://www.rfc-editor.org/rfc/rfc6335#section-6)
                #
                # - shifted ports are rarely used by applications, unlike for example
                #   8000 offset (80 -> 8080) which collides with common application ports
                default = if config.port < 1024 then nextUnblockedPort (10000 + config.port) else config.port;
                defaultText = lib.literalExpression ''
                  if port < 1024 then
                    # Next port not blocked by the browsers, starting from 10000 + port
                    nextUnblockedPort (10000 + port)
                  else
                    port
                '';
                description = ''
                  Host port forwarded to the endpoint `port` by the container and NixOS VM
                  runtimes. Privileged ports (below 1024) are shifted by 10000 by default,
                  skipping the ports blocked by the web browsers (eg. `80` is forwarded to
                  `10081`, because `10080` is blocked).
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
