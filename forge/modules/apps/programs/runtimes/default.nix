{
  lib,
  ...
}:
{
  options = {
    shell = {
      enable = lib.mkEnableOption ''
        Programs bundle output.
      '';
    };
  };
}
