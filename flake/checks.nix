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
    {
      checks = lib.concatMapAttrs (
        packageName: package:
        # `apps` and `pkgs` are invalid dedivations
        # used as package sets (to support the .#apps.${name} syntax)
        # hence filter them out (they do not have a `drvPath` attribute).
        lib.optionalAttrs (lib.isDerivation package && lib.hasAttr "drvPath" package) (
          let
            subDrvs = [
              # All packages passthru attributes
              "env"
              "test"
              # All apps passthru attributes
              "browser"
              "check-programs-main-package"
              "container"
              "program"
              "test"
              "test-browser"
              "test-programs"
              "test-services-container"
              "test-services-nixos"
              "vm"
            ];
          in
          lib.concatMapAttrs (
            attrName: attr:
            {
              # Removing nested derivations so that `nix-eval-jobs --force-recurse`
              # does not re-evaluate them.
              # Explanation: https://github.com/ngi-nix/infra/issues/50#issuecomment-6114094518
              ${packageName} = lib.removeAttrs package subDrvs;
            }
            // lib.optionalAttrs (lib.hasAttr attrName package && lib.isDerivation package.${attrName}) {
              "${packageName}-${attrName}" = package.${attrName};
            }
          ) (lib.genAttrs subDrvs null)
        )
      ) config.packages;
    };
}
