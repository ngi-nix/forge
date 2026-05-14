{
  pkgs,
  ...
}:

{
  apps.jaq = {
    displayName = "jaq";
    description = "Data wrangling tool focusing on correctness, speed, and simplicity.";
    usage = ''
      jaq is a fast and correct reimplementation of jq for processing JSON, YAML, TOML, XML, and CSV data.

      #### Example

      Extract a field from a JSON file

      ```bash
      jaq '.name' file.json
      ```

      Transform an array

      ```bash
      echo '[1,2,3]' | jaq '[.[] * 2]'
      ```

      Filter objects by condition

      ```bash
      jaq '.[] | select(.age > 30)' data.json
      ```

      Output raw strings without JSON encoding

      ```bash
      jaq -r '.items[].name' data.json
      ```
    '';

    links = {
      docs = "https://gedenkt.at/jaq/manual";
      source = "https://github.com/01mf02/jaq";
    };

    ngi.grants = {
      Commons = [
        "Polyglot-jaq"
      ];
      Entrust = [
        "jaq"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.jaq
      ];

      runtimes.shell = {
        enable = true;
      };
    };
  };
}
