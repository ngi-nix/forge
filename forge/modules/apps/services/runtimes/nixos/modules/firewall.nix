{
  app,

  lib,
  ...
}:
let
  endpoints = lib.concatLists (lib.attrValues app.services.result.endpoints);

  # Ports of the endpoints with the transport-level `protocol`.
  ports =
    protocol:
    lib.unique (map (endpoint: endpoint.port) (lib.filter (e: e.protocol == protocol) endpoints));
in
{
  # Open the endpoints exposed to the users of the app.
  networking.firewall = {
    allowedTCPPorts = ports "tcp";
    allowedUDPPorts = ports "udp";
  };
}
