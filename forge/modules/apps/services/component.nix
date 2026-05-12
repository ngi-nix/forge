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
  };
}
