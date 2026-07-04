{ config, lib, ... }: {
  options = {
    packages.build.host = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "A list of native dependencies used by the phase, notably tools needed on `$PATH`.";
    };
    packages.host.target = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "A list of host dependencies used by the phase, usually libraries linked into executables built during tests.";
    };
  };
  config = {
    result.derivationAttrs = {
      doCheck = config.enable;
      nativeCheckInputs = config.packages.build.host;
      checkInputs = config.packages.host.target;
    };
  };
}
