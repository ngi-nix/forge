{
  lib,
  config,
  ...
}:
let
  recipe = config.pkgs.beacondb;
in
{
  pkgs.beacondb = {
    version = "0.2.0";
    description = "A privacy focused assisted GPS service written in Rust.";
    homePage = "https://beacondb.net";
    mainProgram = "beacondb";
    license = lib.licenses.agpl3Only;

    source = {
      git = "github:beacondb/beacondb/v${recipe.version}";
      hash = "sha256-jKSHFtSeykan/cx4cFWjMLaropXskNo5OEwNlA/u3zs=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-4mrcZ9UCOJdUWJkshciB6N4aoHz9tGSmFqp4w56BRtc=";
    };

    test.script = ''
      beacondb --help
    '';
  };
}
