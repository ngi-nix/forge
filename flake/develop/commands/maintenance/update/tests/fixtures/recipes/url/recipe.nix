{
  pkgs,
  ...
}:

{
  pkgs.url = {
    version = "1.2.3";
    description = "URL source, updated with --version rather than detection.";

    source = {
      url = "https://example.com/url-1.2.3.tar.gz";
      hash = "sha256-LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL=";
    };

    build.builders.standard = {
      enable = true;
    };
  };
}
