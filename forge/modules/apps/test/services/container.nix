{
  lib,

  app,
  config,
  pkgs,
  ...
}:
{
  options = {
    result.containerBuild = lib.mkOption {
      internal = true;
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "NixOS test derivation for the container runtime.";
    };
  };

  config = {
    result.containerBuild = lib.mkIf app.services.runtimes.container.enable (
      let
        containerRuntime = app.services.runtimes.container;

        # Publish endpoints also on their original ports, to reach them on the
        # same ports as in the NixOS test.
        originalPorts =
          endpoints:
          map (
            endpoint:
            "${toString endpoint.port}:${toString endpoint.port}"
            + lib.optionalString (endpoint.protocol == "udp") "/udp"
          ) (lib.filter (endpoint: endpoint.forwardedPort != endpoint.port) endpoints);

        composeOverrideFile = pkgs.writeText "${app.name}-compose-test.yaml" (
          lib.generators.toYAML { } {
            services = lib.filterAttrs (_: service: service.ports != [ ]) (
              lib.mapAttrs (_: endpoints: { ports = originalPorts endpoints; }) app.services.result.endpoints
            );
          }
        );
      in
      (pkgs.testers.runNixOSTest {
        name = "${app.name}-container-test";
        nodes.machine = lib.mkMerge [
          {
            virtualisation.podman.enable = true;
            virtualisation.containers.enable = true;
            virtualisation.diskSize = 4096;
            system.stateVersion = "25.11";
            environment.systemPackages = app.programs.packages ++ config.packages ++ [ pkgs.podman-compose ];
          }
          config.nixosConfig
        ];
        testScript = ''
          machine.start()
          machine.wait_for_unit("multi-user.target")
          machine.succeed("COMPOSE_OVERRIDE_FILE=${composeOverrideFile} ${lib.getExe containerRuntime.result.build} --detach")
          machine.succeed("${pkgs.writeShellScript "${app.name}-container-test-script" ''
            set -euo pipefail
            ${config.script}
          ''}")
        '';
      }).overrideTestDerivation
        (_: lib.optionalAttrs (!config.sandbox) { __noChroot = true; })
    );
  };
}
