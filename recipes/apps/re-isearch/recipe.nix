{
  pkgs,
  ...
}:

{
  apps.re-isearch = {
    displayName = "Re-Isearch";
    description = "Novel multimodal search and retrieval engine.";
    usage = ''
      Re-Isearch is a multimodal search engine that supports ranked retrieval across
      structured and unstructured data using a variety of ranking models.

      Index documents

      ```bash
      Iindex -d mydb document.txt
      ```

      Search the index

      ```bash
      Isearch -d mydb searchterm
      ```
    '';

    links = {
      source = "https://github.com/re-Isearch/re-Isearch";
      docs = "https://github.com/re-Isearch/re-Isearch/blob/master/docs/re-Isearch-Handbook.pdf";
    };

    ngi.grants = {
      Commons = [
        "Re-Isearch-Vector"
      ];
      Review = [
        "Re-iSearch"
      ];
    };

    programs = {
      packages = [
        pkgs.re-isearch
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      mkdir -p mydb
      echo "The quick brown fox jumps over the lazy dog" > doc.txt
      Iindex -d mydb/mydb doc.txt 2>&1 | grep -q "records added"
      Isearch -d mydb/mydb fox 2>&1 | grep -q "1 record"
    '';
  };
}
