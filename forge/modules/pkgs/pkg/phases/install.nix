{ config, ... }: {
  options = {
  };
  config = {
    result.derivationAttrs = {
      dontInstall = !config.enable;
    };
  };
}
