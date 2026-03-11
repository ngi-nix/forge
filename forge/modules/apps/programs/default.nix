{
  lib,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Programs bundle output.
    '';
    requirements = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };
}
