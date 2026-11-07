# Format of the items of `process.configData`.
#
# `mkServiceRunner.nix` uses the format to change a field of a file at run time.
{ lib, ... }:
let
  formats = {
    json = "json";
    toml = "toml";
    yaml = "yaml";
    yml = "yaml";
  };
in
{
  options.configData = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.format = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum (lib.unique (lib.attrValues formats)));
            default = formats.${lib.last (lib.splitString "." (baseNameOf config.path))} or null;
            defaultText = lib.literalMD "the format of the file name extension of `path`, or `null`";
            description = ''
              Format of the file. A user of a container can change a field of a
              file with a format. Set to `null` for a file with a format that
              is not in this list. A user can only replace such a file.
            '';
            example = "toml";
          };
        }
      )
    );
  };
}
