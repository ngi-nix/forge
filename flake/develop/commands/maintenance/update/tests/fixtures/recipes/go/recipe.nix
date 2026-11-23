{
  lib,
  pkgs,
  ...
}:

{
  pkgs.go-demo = {
    version = "1.2.3";
    description = "Go recipe with a vendorHash pinned by the snapshot test.";
    homePage = "https://github.com/example/go-demo";
    mainProgram = "go-demo";
    license = lib.licenses.bsd3;

    source = {
      git = "github:example/go-demo/v1.2.3";
      hash = "sha256-FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF=";
    };

    build.builders.go = {
      enable = true;
      vendorHash = "sha256-GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG=";
      packages.build = [ pkgs.go ];
    };

    test.script = ''
      go-demo --version
    '';
  };
}
