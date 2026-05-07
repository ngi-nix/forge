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

          machine.succeed("${lib.getExe containerRuntime.result.build.run-podman} -d")
          machine.succeed("${pkgs.writeShellScript "${app.name}-podman-test-script" config.script}")
          machine.succeed("${lib.getExe containerRuntime.result.build.run-podman-compose} down")

          machine.succeed("${lib.getExe containerRuntime.result.build.run-docker} -d")
          machine.succeed("${pkgs.writeShellScript "${app.name}-docker-test-script" config.script}")
          machine.succeed("${lib.getExe containerRuntime.result.build.run-docker-compose} down")

          machine.succeed("${lib.getExe containerRuntime.result.build.run-container} -d")
          machine.succeed("${pkgs.writeShellScript "${app.name}-auto-test-script" config.script}")
          machine.succeed("${lib.getExe containerRuntime.result.build.run-podman-compose} down")
          machine.succeed("PATH=$(echo $PATH | sed 's/[^:]*podman[^:]*://g') ${lib.getExe containerRuntime.result.build.run-container} -d")

          machine.succeed("${pkgs.writeShellScript "${app.name}-auto-docker-test-script" config.script}")
        '';
      }).overrideTestDerivation
        (_: lib.optionalAttrs (!config.sandbox) { __noChroot = true; })
    );
  };
}
