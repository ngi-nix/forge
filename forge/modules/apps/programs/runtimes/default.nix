{
  lib,
  ...
}:
{
  options = {
    shell = {
      enable = lib.mkEnableOption ''
        Programs shell environment
      '';
    };
  };
}
