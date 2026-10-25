{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        URL of the screenshot image.

        Use this option together with `hash` to fetch the image.
      '';
      example = "https://example.com/screenshot.png";
    };
    hash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hash of the image at `url`, in SRI format.";
      example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    file = lib.mkOption {
      type = lib.types.path;
      default =
        if config.url == null || config.hash == null then
          throw "A screenshot must set `file`, or both `url` and `hash`."
        else
          pkgs.fetchurl {
            inherit (config) url hash;
            # Query strings are not valid in store path names.
            name = lib.strings.sanitizeDerivationName (
              lib.baseNameOf (lib.head (lib.splitString "?" config.url))
            );
          };
      defaultText = lib.literalExpression "pkgs.fetchurl { inherit url hash; }";
      description = ''
        Screenshot image file in PNG, JPEG, GIF or WebP format.

        Defaults to the image fetched from `url`.
      '';
      example = lib.literalExpression "./screenshot.png";
    };
    caption = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Short description of the screenshot.";
      example = "Main window with an open project.";
    };
  };
}
