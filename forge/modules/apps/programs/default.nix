{
  lib,
  specialArgs,
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
        inherit specialArgs;
        modules = [ ./runtimes ];
      };
      default = { };
      description = "Program runtimes.";
    };
  };
}
