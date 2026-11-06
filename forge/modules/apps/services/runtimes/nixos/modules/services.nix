{
  app,

  pkgs,
  lib,
  ...
}:
{
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

      runtimeDirectory = "forge/${serviceName}";
    in
    {
      description = "${app.name}: ${serviceName}";
      wantedBy = [ "default.target" ];
      environment = service.process.environment // {
        XDG_CONFIG_HOME = "/run/${runtimeDirectory}";
      };
      path = service.process.packages;
      startLimitIntervalSec = 0;
      serviceConfig = lib.mkMerge [
        {
          Type = "simple";
          ExecStart = lib.getExe (
            import ../../mkServiceRunner.nix {
              inherit lib pkgs service;
              name = "${app.name}-${serviceName}";
            }
          );
          Restart = "always";
          RestartSec = "1";
          RuntimeDirectory = runtimeDirectory;
          PassEnvironment = lib.attrNames service.process.environment;
          User = lib.mkDefault serviceName;
          Group = lib.mkDefault serviceName;
          StateDirectory = lib.removePrefix "/var/lib/" service.process.stateDir;
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
      after = [ "default.target" ] ++ requiredServiceUnits;
      requires = requiredServiceUnits;
    }
  ) app.services.components;
}
