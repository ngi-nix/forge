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

  users.groups = lib.mkMerge (
    lib.mapAttrsToList (serviceName: _: { ${serviceName} = { }; }) (
      lib.filterAttrs (_: service: service.user != "prefer-dynamic") app.services.components
    )
  );

  users.users = lib.mkMerge (
    lib.mapAttrsToList (serviceName: _: {
      ${serviceName} = {
        isSystemUser = true;
        group = serviceName;
      };
    }) (lib.filterAttrs (_: service: service.user != "prefer-dynamic") app.services.components)
  );

  systemd.services = lib.mapAttrs (
    serviceName: service:
    let
      serviceAfterUnits = map (a: a + ".service") service.after;
    in
    {
      environment = service.environment;
      path = service.packages;
      serviceConfig = lib.mkMerge [
        {
          PassEnvironment = lib.attrNames service.environment;
          User = lib.mkDefault serviceName;
          Group = lib.mkDefault serviceName;
          StateDirectory = serviceName;
          WorkingDirectory = service.stateDir;
        }
        (lib.optionalAttrs (service.user == "prefer-dynamic") {
          DynamicUser = true;
        })
        (lib.optionalAttrs (service.user == "root") {
          User = "root";
        })
      ];
      after = serviceAfterUnits;
      requires = serviceAfterUnits;
    }
  ) app.services.components;
}
