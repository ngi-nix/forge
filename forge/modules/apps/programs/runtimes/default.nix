{
  lib,
  ...
}:
{
  options = {
    program = {
      enable = lib.mkEnableOption ''
        Single program runtime
      '';
    };
    shell = {
      enable = lib.mkEnableOption ''
        Programs shell environment
      '';
    };
  };
}
