{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "IronCalc helper tools";
  mainProgram = "xlsx_2_icalc";

  inherit (systemConfig.forge.packages.ironcalc)
    homePage
    license
    version
    ;

  source = lib.mkMerge [
    systemConfig.forge.packages.ironcalc.source
    {
      patches = [ ./0001-FIX-test-message.patch ];
    }
  ];

  build.rustPackageBuilder = {
    enable = true;
    cargoHash = "sha256-q5DnqhIYKUUqfJ4/TNHYF1QgTbH198QtgirQ+lP30wk=";
    packages.build = [
      pkgs.pkg-config
      pkgs.python3
    ];
    packages.run = [
      pkgs.bzip2
      pkgs.zstd
    ];
  };

  build.extraAttrs = {
    strictDeps = true;
    __structuredAttrs = true;
    doInstallCheck = true;
    installCheckPhase = ''
      { $out/bin/xlsx_2_icalc 2>&1 || true; } | grep -q "Usage:"

      $out/bin/xlsx_2_icalc xlsx/tests/docs/CHOOSE.xlsx test.ic
      test -f test.ic
    '';
  };
}
