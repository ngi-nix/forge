{
  lib,
  pkgs,
  ...
}:

{
  pkgs.ziplinter = {
    version = "0.1.0";
    description = "ZIP file analyzer that outputs detailed archive metadata as JSON.";
    homePage = "https://github.com/trifectatechfoundation/ziplinter";
    mainProgram = "ziplinter";
    license = with lib.licenses; [
      mit
      asl20
    ];

    source = {
      git = "github:trifectatechfoundation/ziplinter/v0.1.0";
      hash = "sha256-YL41HUoQfc9StAAHBR0Gt7r5NFQsh6LjfdFfiYRNB4s=";
    };

    build.rustPackageBuilder = {
      enable = true;
      cargoHash = "sha256-/3W9UtsUwkpkTA5kCnvKsO6O/f1Tzg1Dgp3Y7gGO7Kw=";
      cargoBuildFlags = [
        "--package"
        "ziplinter"
      ];
    };

    build.extraAttrs = {
      doCheck = false;
    };

    test = {
      packages = [ pkgs.zip ];
      script = ''
        echo "hello ziplinter" > /tmp/test.txt
        zip /tmp/test.zip /tmp/test.txt
        ziplinter /tmp/test.zip | grep -q '"contents"'
      '';
    };
  };
}
