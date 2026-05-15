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

    forwardPorts =
      let
        servicePorts = lib.concatMap (service: service.ports) (lib.attrValues app.services.components);
        appPorts = app.services.ports ++ servicePorts;
      in
      map (
        portRange:
        let
          portSplit = lib.splitString ":" portRange;
        in
        {
          from = "host";
          host.port = lib.toInt (lib.elemAt portSplit 0);
          guest.port = lib.toInt (lib.elemAt portSplit 1);
        }
      ) appPorts;
  };
}
