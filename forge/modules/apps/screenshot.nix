{ lib, ... }:
{
  options = {
    file = lib.mkOption {
      type = lib.types.path;
      description = "Screenshot image file in PNG, JPEG, GIF or WebP format.";
      example = lib.literalExpression "./screenshots/main.png";
    };
    caption = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Short description of the screenshot.";
      example = "Main window with an open project.";
    };
  };
}
