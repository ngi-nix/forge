{
  name,
  inputs,
  pkgs,

  lib,
  ...
}:
{
  imports = [
    (lib.modules.importApply (inputs.nixpkgs + "/lib/services/config-data.nix") { inherit pkgs; })
  ];

  options = {
    command = lib.mkOption {
      type = lib.types.either lib.types.package lib.types.str;
      description = "Main command to use for the service.";
    };

    argv = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
      description = "List of arguments that will be passed to the main program.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables.";
      example = lib.literalExpression ''
        {
          DEBUG = "1";
          LOG_LEVEL = "info";
        }
      '';
    };

    preStart = lib.mkOption {
      description = ''
        Script to run before each start of this service.

        Runs before every start attempt, including restarts.
        If the script exits with a non-zero status, the service
        is considered failed and the restart policy applies.

        Set to `null` to disable.
      '';
      type = lib.types.nullOr lib.types.str;
      default = null;
      apply = self: if self != null then pkgs.writeShellScript "${name}-pre-start" self else null;
    };

    readyCheck = lib.mkOption {
      description = ''
        Path to an executable to run to determine if the service is ready.

        The executable should exit 0 when the service is ready.
        It will be polled repeatedly until it succeeds.
        Required for services that will be used as `afterReady` targets.

        Set to `null` to disable.
      '';
      type = lib.types.nullOr lib.types.pathInStore;
      default = null;
      example = lib.literalExpression ''
        lib.getExe (
          pkgs.writeShellApplication {
            name = "example-ready-check";
            text = '''
              curl -f http://localhost:8080/health || exit 1
            ''';
          }
        )
      '';
    };

    type = lib.mkOption {
      description = ''
        Service type, similar to systemd's Type=.

        - `simple` (default): Service runs continuously, expected to stay running.
        - `oneshot`: Service runs once and exits. Considered "started" on successful exit.
        - `notify`: Service sends READY=1 via sd_notify when ready (not yet implemented).
        - `dbus`: Service registers a name on D-Bus (not yet implemented).

        For oneshot services, the restart policy is ignored - the service runs once
        and is considered successful if it exits with code 0.
      '';
      default = "simple";
      example = lib.literalExpression ''"oneshot"'';
      type = lib.types.enum [
        "simple"
        "oneshot"
        "notify"
        "dbus"
      ];
    };
  };
}
