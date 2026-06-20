{ config, ... }: {
  options = {
  };
  config = {
    result.derivationAttrs = {
      dontUnpack = !config.enable;
    };
  };
}
