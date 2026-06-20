{ config, ... }: {
  options = {
  };
  config = {
    result.derivationAttrs = {
      dontPatch = !config.enable;
    };
  };
}
