{
  inputs,
  app,

  lib,
  ...
}:
{

  imports = [
    inputs.ngi-forge.inputs.nimi.nixosModules.default
  ];

  nimi = lib.mapAttrs (serviceName: service: {
    settings.binName = "${serviceName}-service";
    services.${serviceName} = import ../../mkNimiImports.nix {
      inherit lib service;
    };
  }) app.services.components;

  systemd.services = lib.mapAttrs (_: service: {
    environment = service.environment;
    serviceConfig.PassEnvironment = builtins.attrNames service.environment;
  }) app.services.components;
}
