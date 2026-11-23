{
  pkgs,
  ...
}:

{
  pkgs.generic-git-bare = {
    version = "1.2.3";
    description = "Generic git source without a rev or tag query parameter.";

    source = {
      git = "git:https://example.com/generic-git-bare.git";
      hash = "sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=";
    };

    build.builders.standard = {
      enable = true;
    };
  };
}
