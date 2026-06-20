{ config, ... }: {
  options = {
  };
  config = {
    result.derivationAttrs = {
      dontBuild = !config.enable;
    };
  };
}
