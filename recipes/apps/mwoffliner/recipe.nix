{
  lib,
  pkgs,
  ...
}:
{
  apps.mwoffliner = {
    displayName = "MWOffliner";
    description = "Crawls any recent MediaWiki wiki and packages it into an offline ZIM snapshot for local browsing.";
    categories = with lib.categories; [ Development ];
    usage = ''
      MWoffliner scrapes an online MediaWiki instance (like Wikipedia or
      Wiktionary) and packages the pages into an offline ZIM file, viewable with
      a reader like [Kiwix](https://kiwix.org).

      MWoffliner requires a running Redis instance to store scrape state.

      Scrape a wiki into a ZIM file

      ```bash
      mwoffliner --mwUrl=https://bm.wikipedia.org --adminEmail=you@example.com \
        --outputDirectory=/output
      ```

      An actual, reachable email address must be used for `--adminEmail`, since
      it is included in the HTTP User-Agent so wiki operators can identify the
      scraper; dummy addresses may get flagged and blocked by the wiki.

      Limit the scrape to specific content, or specific pages

      ```bash
      mwoffliner --mwUrl=https://en.wikipedia.org --adminEmail=you@example.com \
        --format=nopic:nopic --pageList="Main Page,Earth,Albert Einstein"
      ```

      Run `mwoffliner --help` to see all available options.
    '';

    links = {
      source = "https://github.com/openzim/mwoffliner";
      docs = "https://github.com/openzim/mwoffliner/wiki";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Core = [
        "MWOffliner"
      ];
    };

    programs = {
      mainPackage = pkgs.mwoffliner;
      packages = [ pkgs.mwoffliner ];
      runtimes.shell.enable = true;
      runtimes.program.enable = true;
    };
  };
}
