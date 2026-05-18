{
  inputs,
  app,

  lib,
  ...
}:
{

  imports = [
    inputs.nimi.nixosModules.default
  ];

  nimi = lib.mapAttrs (serviceName: service: {
    settings.binName = "${serviceName}-service";
    services.${serviceName} = import ../../mkNimiImports.nix {
      inherit lib service;
    };
  }) app.services.components;

  systemd.services = lib.mapAttrs (serviceName: service: {
    environment = service.environment;
    serviceConfig = {
      PassEnvironment = builtins.attrNames service.environment;
      StateDirectory = serviceName;
      WorkingDirectory = "/var/lib/${serviceName}";
    };
  }) app.services.components;
}
