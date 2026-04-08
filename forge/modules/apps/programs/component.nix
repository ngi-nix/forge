{
  lib,
  ...
}:
{
  options = {
    requirements = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };
}
