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
    forwardPorts = map (endpoint: {
      from = "host";
      proto = endpoint.protocol;
      host.port = endpoint.forwardedPort;
      guest.port = endpoint.port;
    }) (lib.concatLists (lib.attrValues app.services.result.endpoints));
  };
}
