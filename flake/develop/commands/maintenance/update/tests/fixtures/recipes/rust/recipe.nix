{
  lib,
  pkgs,
  ...
}:

{
  pkgs.rust-demo = {
    version = "1.2.3";
    description = "Rust recipe with a cargoHash pinned by the snapshot test.";
    homePage = "https://github.com/example/rust-demo";
    mainProgram = "rust-demo";
    license = lib.licenses.asl20;

    source = {
      git = "github:example/rust-demo/v1.2.3";
      hash = "sha256-DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE=";
      packages.build = [ pkgs.pkg-config ];
      packages.run = [ pkgs.openssl ];
    };

    build.extraAttrs = {
      doCheck = false;
    };
  };
}
