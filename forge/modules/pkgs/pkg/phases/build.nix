{ config, lib, ... }: {
  options = {
    packages.build.host = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "A list of native dependencies used by the phase, notably tools needed on `$PATH`.";
      example = lib.literalExpression "[ pkgs.cmake pkgs.pkg-config pkgs.ninja ]";
    };
    packages.host.target = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "A list of host dependencies used by the phase, usually libraries linked into executables built during tests.";
      example = lib.literalExpression "[ pkgs.openssl pkgs.sqlite pkgs.zlib ]";
    };
    packages.propagated.build.host = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "The propagated equivalent of `packages.build.host`.";
    };
    packages.propagated.host.target = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "The propagated equivalent of `packages.host.target`.";
    };
  };
  config = {
    result.derivationAttrs = {
      dontBuild = !config.enable;
      strictDeps = true;
      nativeBuildInputs = config.packages.build.host;
      buildInputs = config.packages.host.target;
      propagatedNativeBuildInputs = config.packages.propagated.build.host;
      propagatedBuildInputs = config.packages.propagated.host.target;
    };
  };
}
