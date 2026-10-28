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

    # Forward endpoints to the host.
    forwardPorts =
      let
        services =
          lib.attrValues app.services.components ++ lib.attrValues app.services.result.enabledResources;
        endpoints = lib.concatMap (
          service: lib.sortOn (endpoint: endpoint.port) (lib.attrValues service.endpoints)
        ) services;
      in
      map (endpoint: {
        from = "host";
        host.port = endpoint.forwardedPort;
        guest.port = endpoint.port;
      }) endpoints;
  };
}
