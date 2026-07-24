{ repo_root }:
let
  forgeLegacy = import repo_root { system = "x86_64-linux"; };
  dummy = forgeLegacy.pkgs.hello.overrideAttrs (old: {
    name = "dummy-insecure-pkg-1.0";
    meta = (old.meta or { }) // {
      knownVulnerabilities = [ "test vulnerability" ];
    };
  });
in
dummy.drvPath
