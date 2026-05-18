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
        containerScript = pkgs.writeShellScript "${app.name}-container-test-script" config.script;
      in
      (pkgs.testers.runNixOSTest {
        name = "${app.name}-container-test";
        nodes.machine = {
          virtualisation.podman.enable = true;
          virtualisation.docker.enable = true;
          virtualisation.containers.enable = true;
          virtualisation.diskSize = 4096;
          system.stateVersion = "25.11";
          environment.systemPackages =
            app.programs.packages
            ++ config.packages
            ++ [
              pkgs.podman-compose
              pkgs.docker-compose
            ];
        };
        testScript = ''
          machine.start()
          machine.wait_for_unit("multi-user.target")
          machine.wait_for_unit("docker.service")

          machine.succeed("${lib.getExe containerRuntime.result.build.run-container} -d")
          machine.succeed("${containerScript}")
          machine.succeed("${lib.getExe containerRuntime.result.build.run-podman-compose} down")

          machine.succeed("${lib.getExe containerRuntime.result.build.run-podman} -d")
          machine.succeed("${containerScript}")
          machine.succeed("${lib.getExe containerRuntime.result.build.run-podman-compose} down")

          machine.succeed("${lib.getExe containerRuntime.result.build.run-docker} -d")
          machine.succeed("${containerScript}")
          machine.succeed("${lib.getExe containerRuntime.result.build.run-docker-compose} down")
        '';
      }).overrideTestDerivation
        (_: lib.optionalAttrs (!config.sandbox) { __noChroot = true; })
    );
  };
}
