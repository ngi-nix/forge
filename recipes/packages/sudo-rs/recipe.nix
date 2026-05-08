{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "sudo-rs";
  version = "0.2.13";
  description = "Memory-safe implementation of sudo and su.";
  homePage = "https://github.com/trifectatechfoundation/sudo-rs";
  mainProgram = "sudo";
  license = with lib.licenses; [
    mit
    asl20
  ];

  source = {
    git = "github:trifectatechfoundation/sudo-rs/v0.2.13";
    hash = "sha256-T9QkdpNq7YTR2df1M+lIt+iocVzrFv1yUwq0wgBRHaA=";
  };

  build.rustPackageBuilder = {
    enable = true;
    packages.run = [
      pkgs.pam
    ];
    cargoHash = "sha256-yfML0XO2/Xug0IhbzX1P7PL1YspxWR1FJYP5VtqZzRA=";
  };

  build.extraAttrs = {
    doCheck = false;
  };

  test.script = ''
    visudo -V
  '';
}
