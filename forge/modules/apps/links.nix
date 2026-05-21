{
  lib,
  ...
}:
let
  # https://www.rfc-editor.org/rfc/rfc3986#section-3.1
  link = lib.types.strMatching "[a-zA-Z][a-zA-Z0-9+\-.]*://[^ \t\n]+";
in
{
  options = {
    website = lib.mkOption {
      type = lib.types.nullOr link;
      default = null;
      description = "Project website URL.";
      example = "https://example.com";
    };
    source = lib.mkOption {
      type = lib.types.nullOr link;
      default = null;
      description = "Project source code URL.";
      example = "https://github.com/example/project";
    };
    docs = lib.mkOption {
      type = lib.types.nullOr link;
      default = null;
      description = "Project documentation URL.";
      example = "https://example.com/docs";
    };
  };
}
