{ lib, ... }:
{
  options.structuredAttrs = lib.mkOption {
    description = ''
      Attributes local to the buildscript.

      Mapped to themselves as attributes given to `stdenv.mkDerivation`.
    '';
    default = { };
    apply = lib.filterAttrs (k: v: v != null);
    type = lib.types.submodule {
      freeformType =
        with lib.types;
        attrsOf (
          lib.types.serializableValueWith {
            typeName = "structuredAttrs";
            nullable = true;
          }
        );
    };
  };
}
