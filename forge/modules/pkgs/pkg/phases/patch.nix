{ config, lib, ... }: {
  options = {
    patches = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        List of patch files to be applied to the source code.

        Patches are applied in the order specified using the patch command.
      '';
      example = lib.literalExpression "[ ./fix-build.patch ./add-feature.patch ]";
    };
    flags = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "-p1" ];
      description = "Additional arguments to the patch command.";
    };
  };
  config = {
    result.derivationAttrs = {
      dontPatch = !config.enable;
      patches = config.patches;
      patchFlags = config.flags;
    };
  };
}
