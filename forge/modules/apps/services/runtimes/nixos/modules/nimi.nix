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

  environment.variables = lib.concatMapAttrs (_: value: value.environment) app.services.components;
}
