{
  config,
  name,
  lib,
  pkgs,
  valueType,
  ...
}:
{
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = name;
      description = ''
        Data item name.

        Defaults to the file's basename when sourced from a path, or to the
        attribute name otherwise.
      '';
    };
    value = lib.mkOption {
      type = valueType;
      default =
        let
          binaryExts = [
            ".png"
            ".jpg"
            ".ico"
          ];

          # https://github.com/NixOS/nix/issues/1307
          isBinary = lib.elem true (map (ext: lib.hasSuffix ext config.path) binaryExts);
        in
        if config.path != null && !isBinary then lib.removeSuffix "\n" (lib.readFile config.path) else "";
      apply = lib.trim;
      defaultText = lib.literalExpression ''if config.path != null && !isBinary then lib.removeSuffix "\n" (lib.readFile config.path) else ""'';
      description = "Data item content. Will be an empty string for binary files as nix doesn't support reading binary files.";
    };
    path = lib.mkOption {
      type = lib.types.path;
      default = pkgs.writeText config.name (toString config.value);
      defaultText = lib.literalExpression "pkgs.writeText config.name (toString config.value)";
      description = "Data item absolute path.";
    };
    __toString = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      default = self: toString self.value;
    };
  };
}
