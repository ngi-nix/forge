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
      checks = {
        ui-test =
          let
            ui = config.packages."_forge.ui";
            testUiCmd = pkgs.callPackage ./develop/commands/dev/test-ui { };
            testUiSrc = lib.fileset.toSource {
              root = ../ui/tests/e2e;
              fileset = lib.fileset.intersection (lib.fileset.gitTracked ../.) ../ui/tests/e2e;
            };
          in
          pkgs.runCommand "ui-test"
            {
              nativeBuildInputs = [
                testUiCmd
                pkgs.esbuild
              ];
              env = {
                CI = "true";
                FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; };
                UI_CMD = "esbuild --serve=127.0.0.1:3000 --servedir=${ui} --serve-fallback=${ui}/index.html";
                TEST_APP_NAME = "emerge";
                TEST_APP_SEARCH = "emerge";
                TEST_PKG_NAME = "emerge";
                TEST_PKG_SEARCH = "emerge";
              };
            }
            ''
              export HOME="$TMPDIR"

              mkdir -p ui/tests
              cp -r ${testUiSrc} ui/tests/e2e
              chmod -R u+w ui

              test-ui --project=chromium

              cp -r ui/tests/e2e/playwright-report $out
            '';
      }
      // lib.concatMapAttrs (
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
              "check-programs-main-package"
              "container"
              "program"
              "test"
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
