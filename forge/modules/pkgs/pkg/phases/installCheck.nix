{ config, lib, ... }: {
  options = {
    target = lib.mkOption {
      type = with lib.types; str;
      default = "installcheck";
      description = "The `make` target that runs the install tests.";
    };
    flags = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "A list of additional flags given to `make`.";
    };
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
    enable = lib.mkDefault false;
    result.derivationAttrs = {
      doInstallCheck = config.enable;
      installCheckTarget = config.target;
      installCheckFlags = config.flags;
      nativeInstallCheckInputs = config.packages.build.host;
      installCheckInputs = config.packages.host.target;
    };
  };
}
