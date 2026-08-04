{
  lib,
  ...
}:

{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:

    let
      # Some derivations aren't acutally real (e.g. the toplevel "apps" and "pkgs"),
      # which we don't want to include in the checks.
      isRealDrv = v: lib.isDerivation v && v ? drvPath;

      nonBrokenPackages = lib.filterAttrs (
        n: v: (isRealDrv v && !(v.passthru.forge.broken or false))
      ) config.packages;

      # Helper function to extract passthru attribute, ensuring it is a valid derivation
      passthruAttr =
        attr:
        lib.filterAttrs (_: v: v != null) (
          lib.mapAttrs' (
            name: package:
            if lib.hasAttr attr package && lib.isDerivation package.${attr} then
              lib.nameValuePair "${name}-${attr}" package.${attr}
            else
              lib.nameValuePair name null
          ) nonBrokenPackages
        );
    in

    {
      checks =
        nonBrokenPackages

        # All packages passthru attributes
        // (passthruAttr "env")
        // (passthruAttr "test")

        # All apps passthru attributes
        // (passthruAttr "programs")
        // (passthruAttr "container")
        // (passthruAttr "vm")
        // (passthruAttr "test")
        // (passthruAttr "test-services-container")
        // (passthruAttr "test-services-nixos")
        // (passthruAttr "test-programs")
        // (passthruAttr "check-programs-main-package");
    };
}
