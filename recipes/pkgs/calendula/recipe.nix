{
  lib,
  ...
}:

{
  pkgs.calendula = {
    version = "0.2.0";
    description = "CLI to manage calendars supporting CalDAV and ICS.";
    homePage = "https://pimalaya.org";
    mainProgram = "calendula";
    license = lib.licenses.agpl3Plus;

    source = {
      git = "github:pimalaya/calendula/v0.2.0";
      hash = "sha256-Rw9g/EdYElglrYF4VPe6xn6A4kg/WY1MFoLVP4vn1v8=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-3CwtSy8u6SKxKs8eTUgz0ctt667tfR5yB3EL1eWmn9c=";
    };

    # Same pimalaya codebase pattern as cardamum — doc comments contain shell
    # and iCalendar examples not marked `ignore`, causing doctest failures.
    build.extraAttrs = {
      cargoTestFlags = [
        "--bins"
      ];
    };

    test.script = ''
      calendula --version
      calendula --help
    '';
  };
}
