{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ironcalc-tools";
  version = "0.7.1-unstable-2026-04-29";
  description = "IronCalc helper tools";
  homePage = "https://www.ironcalc.com";
  license = with lib.licenses; [
    mit
    asl20
  ];
  mainProgram = "xlsx_2_icalc";

  source = {
    git = "github:ironcalc/ironcalc/8461ff71347ab19145cd7ad50ef829181ba765c2";
    hash = "sha256-vjI3M+hS9bXK8QQlopAy6f4dCISfQHGMvN9sMNKp88Q=";
    patches = [ ./0001-FIX-test-message.patch ];
  };

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
