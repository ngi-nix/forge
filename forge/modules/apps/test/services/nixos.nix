{
  lib,

  app,
  config,
  pkgs,
  ...
}:
{
  options = {
    testScript = lib.mkOption {
      internal = true;
      type = lib.types.str;
      default = ''
        machine.start()
        machine.wait_for_unit("multi-user.target")
        ${lib.concatMapAttrsStringSep "\n" (
          name: _: "machine.wait_for_unit(\"${name}.service\")"
        ) app.services.components}
        machine.succeed("${pkgs.writeShellScript "${app.name}-test-script" config.script}")
      '';
      description = "Python test script passed to the NixOS test driver.";
    };

    result.build = lib.mkOption {
      internal = true;
      type = lib.types.package;
      description = "NixOS test derivation.";
    };
  };

  config = {
    result.build =
      (pkgs.testers.runNixOSTest {
        name = "${app.name}-test";
        nodes.machine = {
          imports = [ app.services.runtimes.nixos.result.nixosModule ];
          # Pass entropy from host to VM to prevent slow service startup due to entropy starvation.
          virtualisation.qemu.options = [ "-device virtio-rng-pci" ];
          system.stateVersion = "25.11";
          environment.systemPackages = app.programs.packages ++ config.packages;
        };
        inherit (config) testScript;
      }).overrideTestDerivation
        (_: lib.optionalAttrs (!config.sandbox) { __noChroot = true; });
  };
}
