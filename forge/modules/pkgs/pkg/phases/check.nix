{ config, ... }: {
  options = {
  };
  config = {
    result.derivationAttrs = {
      doCheck = config.enable;
    };
  };
}
