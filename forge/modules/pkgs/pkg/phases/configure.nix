{ config, lib, ... }: {
  options = {
    flags = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Additional arguments to the configure script.";
    };
  };
  config = {
    result.derivationAttrs = {
      dontConfigure = !config.enable;
      configureFlags = config.flags;
    };
  };
}
