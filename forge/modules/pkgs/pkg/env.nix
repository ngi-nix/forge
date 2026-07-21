{ lib, ... }:
{
  options.env = lib.mkOption {
    type = lib.types.submodule {
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
