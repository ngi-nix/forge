{
  name,
  inputs,
  pkgs,

  lib,
  ...
}:
{
  imports = [
    (lib.modules.importApply (inputs.ngi-forge.inputs.nixpkgs + "/lib/services/config-data.nix") {
      inherit pkgs;
    })
  ];

  options = {
    name = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.str;
      default = name;
      description = "Name of service component.";
    };

    command = lib.mkOption {
      type = lib.types.either lib.types.package lib.types.str;
      description = ''
        Main command used to launch a service.

        Can be a package (e.g. `pkgs.hello`) or an explicit binary path.
      '';
      example = lib.literalExpression ''"''${pkgs.hello}/bin/hello"'';
    };

    argv = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
      description = "List of arguments that will be passed to the main program.";
      example = [
        "--config"
        "service.toml"
      ];
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables passed to the service.";
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
      example = ''
        # bash
        echo "Running DB migration ..."
        program-manage makemigrations && program-manage migrate
      '';
    };

    user = lib.mkOption {
      type = lib.types.enum [
        "root"
        "prefer-dynamic"
        "non-privileged"
      ];
      default = "prefer-dynamic";
      description = ''
        User account under which the service runs.

        - `root`: service runs as root. A non-privileged user and group named
          after the service are also created for services that start as root
          and then drop privileges.

        - `prefer-dynamic`: on NixOS runtime , uses `DynamicUser` - no physical
          user or group account is created. On container runtime, uses a
          non-privileged user named after the service.

        - `non-privileged`: service always runs as a non-privileged user named
          after the service.
      '';
    };

    ports = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "^[0-9]+:[0-9]+$");
      default = [ ];
      description = ''
        List of ports exposed by the service.

        Format:
          _HOST_PORT:SERVICE_PORT_
      '';
      example = lib.literalExpression ''
        [ "8000:8000" "5432:5432" ]
      '';
    };

    after = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of service components that need to be started before this one.
      '';
      example = lib.literalExpression ''
        [ "foobar-server" ]
      '';
    };
  };
}
