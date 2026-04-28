{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "offen-script";
  version = "0.0.0-unstable-2026-03-04";
  description = "Client-side analytics script for Offen.";
  homePage = "https://www.offen.dev";
  license = lib.licenses.asl20;

  source = {
    git = "github:offen/offen/ec99082a37ffb5855bd84debfef227d41c7b403c";
    hash = "sha256-EGlqD3611sG3YTVe74H49PB8Hj1NsKYhLANg5VAQ0wg=";
  };

  build.pnpmPackageBuilder = {
    enable = true;
    pnpmDepsHash = "sha256-Vmv4aESpAvE9Dg28WpSPhtEEBr8q/BfqrJl5EXC0nl4=";
    sourceRoot = "source/script";
    buildScript = "build";
    installDir = "dist";
  };

  build.extraAttrs = {
    preBuild = ''
      cp -r ../locales locales
    '';
  };
}
