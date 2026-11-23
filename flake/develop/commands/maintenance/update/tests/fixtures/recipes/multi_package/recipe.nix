{
  pkgs,
  ...
}:

{
  pkgs.a = {
    version = "1.2.3";
    description = "First package: updated by the snapshot test.";
    source = {
      git = "github:example/a/v1.2.3";
      hash = "sha256-IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII=";
    };
    build.builders.standard = {
      enable = true;
    };
  };

  pkgs.b = {
    version = "4.5.6";
    description = "Second package: must be left untouched.";
    source = {
      git = "github:example/b/v4.5.6";
      hash = "sha256-JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ=";
    };
    build.builders.standard = {
      enable = true;
    };
  };
}
