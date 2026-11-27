{
  lib,
  pkgs,
  ...
}:

{
  pkgs.basic = {
    version = "1.2.3";
    description = "Minimal forge-host recipe used by the snapshot tests.";
    homePage = "https://github.com/example/basic";
    mainProgram = "basic";
    license = lib.licenses.mit;

    source = {
      git = "github:example/basic/v1.2.3";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    build.builders.standard = {
      enable = true;
      packages.build = [ pkgs.pkg-config ];
    };

    test.script = ''
      basic --version
    '';
  };
}
