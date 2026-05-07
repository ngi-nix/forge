{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ziplinter";
  version = "0.1.0";
  description = "ZIP file analyzer that outputs detailed archive metadata as JSON.";
  homePage = "https://github.com/trifectatechfoundation/ziplinter";
  mainProgram = "ziplinter";
  license = lib.licenses.mit;

  source = {
    git = "github:trifectatechfoundation/ziplinter/v0.1.0";
    hash = "sha256-YL41HUoQfc9StAAHBR0Gt7r5NFQsh6LjfdFfiYRNB4s=";
  };

  build.rustPackageBuilder = {
    enable = true;
    # target only the CLI binary from the Cargo workspace
    cargoBuildFlags = [ "--package" "ziplinter" ];
    cargoHash = "sha256-RjMp+9VfIalGcDGLdncYg/6KjIodR/9IMGQZw9/g2EM=";
  };

  build.extraAttrs = {
    # upstream snapshot tests (insta) require stored fixtures;
    # functionality is verified via test.script instead
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
}
