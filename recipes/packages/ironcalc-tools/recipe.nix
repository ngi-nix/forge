{
  packages.ironcalc-tools =
    {
      config,
      lib,
      pkgs,
      packages,
      ...
    }:

    {
      version = "0.7.1-unstable-2026-04-29";
      description = "IronCalc helper tools";
      homePage = "https://www.ironcalc.com";
      license = with lib.licenses; [
        mit
        asl20
      ];
      mainProgram = "xlsx_2_icalc";

      source = {
        inherit (packages.ironcalc.source) git hash;
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

    };
}
