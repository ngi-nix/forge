{
  pkgs,
  ...
}:
{
  apps.lychee = {
    displayName = "Lychee";
    description = "Reliable and fast link checker to combat linkrot.";
    usage = ''
      Recursively checks all links in all supported files.

      ```bash
      lychee .
      ```

      Checks links on the given page (not recursive). Recursion is not supported, but you can use a sitemap as input.

      ```bash
      lychee https://example.com
      ```

      Checks multiple inputs, such as files and URLs.

      ```bash
      lychee README.md
      lychee test.html info.txt https://example.com
      ```

      Checks local files without making any network requests.

      ```bash
      lychee --offline path/to/directory
      ```
    '';
    icon = ./icon.svg;

    links = {
      docs = "https://lychee.cli.rs/guides/getting-started";
      website = "https://lychee.cli.rs";
      source = "https://github.com/lycheeverse/lychee";
    };

    ngi.grants = {
      Core = [ "lychee" ];
    };

    programs = {
      packages = [ pkgs.lychee ];
      runtimes.shell.enable = true;
    };
  };
}
