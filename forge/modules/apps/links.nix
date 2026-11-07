{
  lib,
  ...
}:
let
  link = import ./link-type.nix { inherit lib; };
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
