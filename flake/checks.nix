{
  lib,
  self,
  inputs,
  ...
}:

{
  perSystem =
    {
      config,
      pkgs,
      self',
      system,
      ...
    }:

    let
      # Helper function to extract passthru attribute, ensuring it is a valid derivation
      passthruAttr =
        attr:
        lib.filterAttrs (_: v: v != null) (
          lib.mapAttrs' (
            name: package:
            if lib.hasAttr attr package && lib.isDerivation package.${attr} then
              let
                evalResult = builtins.tryEval (
                  package.${attr} ? drvPath && builtins.seq package.${attr}.drvPath true
                );
              in
              if evalResult.success && evalResult.value then
                lib.nameValuePair "${name}-${attr}" package.${attr}
              else
                lib.nameValuePair name null
            else
              lib.nameValuePair name null
          ) config.packages
        );
    in

    {
      checks =
        (lib.filterAttrs (_: v: v != null) (
          lib.mapAttrs (
            name: package:
            if lib.isDerivation package then
              let
                evalResult = builtins.tryEval (package ? drvPath && builtins.seq package.drvPath true);
              in
              if evalResult.success && evalResult.value then package else null
            else
              null # Ignore non-derivations in config.packages for checks
          ) config.packages
        ))

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
