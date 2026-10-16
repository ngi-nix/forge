{ config, ... }: {
  options = {
  };
  config = {
    result.derivationAttrs = {
      dontFixup = !config.enable;
    };
  };
}
