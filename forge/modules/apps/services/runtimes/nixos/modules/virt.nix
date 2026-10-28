{
  config,
  lib,
  app,
  ...
}:

{
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  virtualisation = {
    graphics = false;

    inherit (config.vm)
      cores
      diskSize
      memorySize
      ;

    # Pass entropy from host to VM to prevent slow service startup due to entropy starvation.
    qemu.options = [ "-device virtio-rng-pci" ];

    # Forward public endpoints to the host.
    forwardPorts =
      let
        endpoints = lib.concatMap (service: lib.attrValues service.endpoints) (
          lib.attrValues app.services.components ++ lib.attrValues app.services.result.enabledResources
        );
        publicEndpoints = lib.filter (endpoint: endpoint.visibility == "public") endpoints;
      in
      map (endpoint: {
        from = "host";
        host.port = endpoint.forwardedPort;
        guest.port = endpoint.port;
      }) (lib.sort (a: b: a.port < b.port) publicEndpoints);
  };
}
