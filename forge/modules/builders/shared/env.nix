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
      options = {
        NIX_CFLAGS_COMPILE = lib.mkOption {
          type = with lib.types; nullOr (listOf str);
          default = null;
          visible = false;
          description = ''
            Flags to pass to the C compiler, bypassing help builders.

            Prefer to use help builders whenever possible.
            See <https://github.com/NixOS/nixpkgs/issues/79303>
          '';
          apply = xs: if xs == null then null else lib.concatStringsSep " " xs;
        };
      };
    };
  };
}
