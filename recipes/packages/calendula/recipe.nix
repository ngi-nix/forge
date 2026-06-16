{
  lib,
  ...
}:

{
  pkgs.calendula = {
    version = "0.1.0";
    description = "CLI to manage calendars supporting CalDAV and ICS.";
    homePage = "https://pimalaya.org";
    mainProgram = "calendula";
    license = lib.licenses.agpl3Plus;

    source = {
      git = "github:pimalaya/calendula/v0.1.0";
      hash = "sha256-xMd4T+vQHcnqSVPXSZ3suQuMKmWpaI4T2gmljrVPk0w=";
    };

    build.rustPackageBuilder = {
      enable = true;
      cargoHash = "sha256-FIcGgPsOi2e+0dU5FRCVvlEkcZoxQ4H+Uro60wYpBQc=";
    };

    # Same pimalaya codebase pattern as cardamum — doc comments contain shell
    # and iCalendar examples not marked `ignore`, causing doctest failures.
    build.extraAttrs = {
      cargoTestFlags = [
        "--lib"
        "--bins"
      ];
    };

    test.script = ''
      calendula --version
      calendula --help
    '';
  };
}
