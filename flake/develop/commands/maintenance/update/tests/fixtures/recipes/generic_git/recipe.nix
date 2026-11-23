{
  pkgs,
  ...
}:

{
  pkgs.generic-git = {
    version = "1.2.3";
    description = "Generic git source with a tag query parameter.";
    license = {
      spdx = "MIT";
      fullText = "MIT License";
    };

    source = {
      git = "git:https://example.com/generic-git.git?tag=v1.2.3&depth=1";
      hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
    };

    build.builders.standard = {
      enable = true;
    };
  };
}
