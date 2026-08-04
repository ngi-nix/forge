{
  lib,
  ...
}:

{
  pkgs.cardamum = {
    version = "0.1.0";
    description = "CLI to manage contacts supporting CardDAV and Vdir.";
    homePage = "https://pimalaya.org";
    mainProgram = "cardamum";
    license = lib.licenses.agpl3Plus;

    source = {
      git = "github:pimalaya/cardamum/v0.1.0";
      hash = "sha256-2JnaAmC2xBfqe0zBjAaL/Xd0/W1DxNJB/skpI2LaY28=";
    };

    build.rustPackageBuilder = {
      enable = true;
      cargoHash = "sha256-SA3QIwiJFEeNkScYv/VFREehdjeZU8L6XExNKcLIn1g=";
    };

    # Upstream lib.rs has shell/VCard examples in doc comments not marked
    # `ignore`, causing doctest compilation failures. Unit tests pass fine.
    build.extraAttrs = {
      cargoTestFlags = [
        "--lib"
        "--bins"
      ];
    };

    test.script = ''
      cardamum --version
      cardamum --help
    '';
  };
}
