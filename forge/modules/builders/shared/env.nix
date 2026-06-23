{ lib, ... }:
{
  options.env = lib.mkOption {
    description = ''
      Exported environment variables.

      Mapped to `env`.
    '';
    default = { };
    apply = lib.filterAttrs (k: v: v != null);
    type = lib.types.submodule {
      freeformType =
        with lib.types;
        attrsOf (
          nullOr (oneOf [
            package
            str
            bool
            int
          ])
        );
    };
  };
}
