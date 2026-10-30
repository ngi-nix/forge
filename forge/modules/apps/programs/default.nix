{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    packages = lib.mkOption {
      type = lib.types.either (lib.types.functionTo (lib.types.listOf lib.types.package)) (
        lib.types.listOf lib.types.package
      );
      apply = v: if lib.isFunction v then v pkgs else v;
      default = [ ];
      description = "Packages to include in the _shell_ runtime.";
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
      type = lib.types.nullOr (
        lib.types.either (lib.types.functionTo lib.types.package) lib.types.package
      );
      apply = v: if lib.isFunction v then v pkgs else v;
      default = null;
      description = "Package launched by the _program_ runtime.";
      example = lib.literalExpression "pkgs.hello";
    };

    runProgram = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = config.mainPackage.meta.mainProgram or "";
      defaultText = lib.literalExpression ''config.mainPackage.meta.mainProgram or ""'';
      description = "Program used to launch the `mainPackage`.";
    };
  };
}
