{
  forge-inputs,
  app,

  pkgs,
  lib,
  ...
}:
{

  imports = [
    forge-inputs.nimi.nixosModules.default
  ];

  nimi = lib.mapAttrs (serviceName: service: {
    settings.binName = "${serviceName}-service";
    services = import ../../mkNimiImports.nix { inherit lib service serviceName; };
  }) app.services.components;

  users.groups = lib.mkMerge (
    lib.mapAttrsToList (serviceName: _: { ${serviceName} = { }; }) (
      lib.filterAttrs (_: service: service.process.user != "prefer-dynamic") app.services.components
    )
  );

  users.users = lib.mkMerge (
    lib.mapAttrsToList (serviceName: _: {
      ${serviceName} = {
        isSystemUser = true;
        group = serviceName;
      };
    }) (lib.filterAttrs (_: service: service.process.user != "prefer-dynamic") app.services.components)
  );

  systemd.services = lib.mapAttrs (
    serviceName: service:
    let
      requiredServiceUnits = map (a: a + ".service") (
        lib.filter (a: app.services.components ? ${a}) service.dependsOn
      );

    in
    {
      environment = service.process.environment;
      path = service.process.packages;
      serviceConfig = lib.mkMerge [
        {
          PassEnvironment = lib.attrNames service.process.environment;
          User = lib.mkDefault serviceName;
          Group = lib.mkDefault serviceName;
          StateDirectory = serviceName;
          WorkingDirectory = service.process.stateDir;
        }
        (lib.optionalAttrs (service.process.user == "prefer-dynamic") {
          DynamicUser = true;
        })
        (lib.optionalAttrs (service.process.user == "root") {
          User = "root";
        })
        (lib.optionalAttrs service.healthcheck.enable {
          ExecStartPost =
            let
              hc = service.healthcheck;
              name = "${serviceName}-healthcheck";
            in
            lib.getExe (
              pkgs.writeShellApplication {
                name = name;
                runtimeInputs = [ pkgs.coreutils ] ++ hc.packages;
                text = ''
                  sleep ${hc.startPeriod}
                  for _ in $(seq 1 ${toString hc.retries}); do
                    if timeout ${hc.timeout} ${lib.escapeShellArgs hc.test}; then
                      exit 0
                    fi
                    sleep ${hc.interval}
                  done
                  exit 1
                '';
              }
            );
          TimeoutStartSec = "infinity";
        })
      ];
      after = requiredServiceUnits;
      requires = requiredServiceUnits;
    }
  ) app.services.components;
}
