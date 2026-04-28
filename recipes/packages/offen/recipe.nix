{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "offen";
  version = "0.0.0-unstable-2026-03-04";
  description = "Fair and privacy-focused web analytics.";
  homePage = "https://www.offen.dev";
  mainProgram = "offen";
  license = lib.licenses.asl20;

  source = {
    git = "github:offen/offen/ec99082a37ffb5855bd84debfef227d41c7b403c";
    hash = "sha256-EGlqD3611sG3YTVe74H49PB8Hj1NsKYhLANg5VAQ0wg=";
  };

  build.goPackageBuilder = {
    enable = true;
    vendorHash = "sha256-AeQa5oaOEB/50aPCRq702vMEtEctwP+jU5C6zB+3XR0=";
    subPackages = [ "cmd/offen" ];
    ldflags = [
      "-s"
      "-w"
    ];
  };

  build.extraAttrs = {
    modRoot = "server";

    # Copy JS frontend assets into public/static before building.
    # Note: preBuild runs after configurePhase which cds into modRoot (server/).
    preBuild = ''
      cp -rT --no-preserve=mode ${pkgs.mypkgs.offen-script} public/static
      cp -rT --no-preserve=mode ${pkgs.mypkgs.offen-vault} public/static
      cp -rT --no-preserve=mode ${pkgs.mypkgs.offen-auditorium} public/static
    '';
  };

  test.script = ''
    offen --help
  '';
}
