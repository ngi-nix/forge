{
  config,
  lib,
  ...
}:
{
  options = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages to include in the shell enviornment.";
      example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
    };

    runtimes = lib.mkOption {
      type = lib.types.submoduleWith {
        modules = [ ./runtimes ];
      };
      default = { };
      description = "Program runtimes.";
    };

    mainPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Main package for the application";
    };

    runCommand = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = config.mainPackage.meta.mainProgram or "";
      defaultText = lib.literalExpression ''config.mainPackage.meta.mainProgram or ""'';
      description = "Main command for the application";
    };
  };
}
