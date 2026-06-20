{ config, lib, ... }: {
  options = {
    sourceRoot = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        If not empty, path to a subdirectory within the source to use as root of the package's source.

        Use this for monorepos where the source you're interested in is not at the repository root.
        Format: `"source/<subdir>"`.

        Mapped to `sourceRoot`.
      '';
      example = "source/frontend";
    };
  };
  config = {
    result.derivationAttrs = {
      dontUnpack = !config.enable;
      sourceRoot = config.sourceRoot;
    };
  };
}
