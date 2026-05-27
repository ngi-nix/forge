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
    services = import ../../mkNimiImports.nix { inherit lib service serviceName; };
  }) app.services.components;

  systemd.services = lib.mapAttrs (
    _: service:
    let
      serviceAfterUntis = map (a: a + ".service") service.after;
    in
    {
      environment = service.environment;
      serviceConfig.PassEnvironment = lib.attrNames service.environment;
      after = serviceAfterUntis;
      requires = serviceAfterUntis;
    }
  ) app.services.components;
}
