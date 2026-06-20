{ config, lib, ... }: {
  options = {
  };
  config = {
    enable = lib.mkDefault false;
    result.derivationAttrs = {
      doDist = config.enable;
    };
  };
}
