{
  inputs,
  config,
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
      # Helper function to extract passthru attribute
      passthruAttr =
        attr:
        lib.filterAttrs (_: v: v != null) (
          lib.mapAttrs' (
            name: package:
            if lib.hasAttr attr package then
              lib.nameValuePair "${name}-${attr}" package.${attr}
            else
              lib.nameValuePair name null
          ) config.packages
        );

      # All output packages
      allPackages = lib.filterAttrs (n: v: !lib.hasPrefix "_forge" n) config.packages;

      # Configuration checks
      configurationChecks = [
        {
          name = "missing test scripts";
          errors =
            map (app: "App '${app.name}' is missing test.script") (
              lib.filter (
                app: app.services.components != { } && app.services.test.script == null
              ) config.forge.apps
            )
            ++ map (pkg: "Package '${pkg.name}' is missing test.script") (
              lib.filter (pkg: pkg.test.script == null) config.forge.packages
            );
        }
      ];

      testConfiguration = pkgs.runCommand "testConfiguration" { } (
        let
          errors = lib.concatMap (c: c.errors) configurationChecks;
        in
        if errors == [ ] then
          "touch $out"
        else
          ''
            echo "Configuration errors:"
            ${lib.concatMapStringsSep "\n" (e: "echo '  - ${e}'") errors}
            exit 1
          ''
      );
    in

    {
      checks = {
        inherit (config.packages) _forge-config _forge-options _forge-ui;
        inherit testConfiguration;
      }
      // allPackages

      # All packages passthru attributes
      // (passthruAttr "devenv")
      // (passthruAttr "test")

      # All apps passthru attributes
      // (passthruAttr "programs")
      // (passthruAttr "container")
      // (passthruAttr "vm")
      // (passthruAttr "test")
      // (passthruAttr "test-container")
      // (passthruAttr "test-program");
    };
}
