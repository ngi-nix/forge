{
  lib,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Container images output.
    '';
    images = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "app-container";
            };
            requirements = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
            };
            config = {
              CMD = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };
          };
        }
      );
      default = [ ];
      description = "List of container images to build.";
      example = lib.literalExpression ''
        [
          {
            name = "api";
            requirements = [ mypkgs.my-package ];
            config.CMD = [ "my-command" ];
          }
        ]
      '';
    };
    composeFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Relative path to a container compose file.";
      example = "./compose.yaml";
    };
  };
}
