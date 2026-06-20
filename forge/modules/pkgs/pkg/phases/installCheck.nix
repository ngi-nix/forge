{ config, lib, ... }: {
  options = {
  };
  config = {
    enable = lib.mkDefault false;
    result.derivationAttrs = {
      doInstallCheck = config.enable;
    };
  };
}
