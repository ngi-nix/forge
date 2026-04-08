{
  lib,
  ...
}:
{
  options = {
    components = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = [ ./component.nix ];
        }
      );
      default = { };
      description = "Program components.";
      example = lib.literalExpression ''
        {
          default = {
            requirements = [ pkgs.curl ];
          };
        }
      '';
    };

    runtimes = lib.mkOption {
      type = lib.types.submoduleWith {
        modules = [ ./runtimes ];
      };
      default = { };
      description = "Program runtimes.";
    };
  };
}
