{
  lib,
  ...
}:

{
  pkgs.cardamum = {
    version = "0.3.0";
    description = "CLI to manage contacts supporting CardDAV and Vdir.";
    homePage = "https://pimalaya.org";
    mainProgram = "cardamum";
    license = lib.licenses.agpl3Plus;

    source = {
      git = "github:pimalaya/cardamum/v0.3.0";
      hash = "sha256-2tN7RXMXTdRNlbp3h7Xb0n65skP+RaYmaCSnO2eYFfQ=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-AyeaPRxnTP8FYqrt1VNvImfje2NsILVxq17kIoOsx8M=";
    };

    # Upstream lib.rs has shell/VCard examples in doc comments not marked
    # `ignore`, causing doctest compilation failures. Unit tests pass fine.
    build.extraAttrs = {
      cargoTestFlags = [
        "--bins"
      ];
    };

    test.script = ''
      cardamum --version
      cardamum --help
    '';
  };
}
