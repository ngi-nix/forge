{
  lib,
  ...
}:
{
  options = {
    program = {
      enable = lib.mkEnableOption ''
        Program runtime
      '';
    };
    shell = {
      enable = lib.mkEnableOption ''
        Shell runtime
      '';
    };
  };
}
