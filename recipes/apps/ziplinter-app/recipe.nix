{
  pkgs,
  ...
}:

{
  apps.ziplinter = {
    displayName = "Ziplinter";
    description = "ZIP file analyzer that outputs detailed archive metadata as JSON.";
    usage = ''
      Ziplinter reads a ZIP archive and outputs detailed metadata about its contents as JSON.

      #### Example

      Run ziplinter against a ZIP file

      ```
      ziplinter archive.zip
      ```

      The output is a JSON object with a `"contents"` key listing all archived files along
      with their compression method, sizes, and other metadata.
    '';

    links = {
      source = "https://github.com/trifectatechfoundation/ziplinter";
    };

    ngi.grants = {
      Commons = [
        "ZipLinting"
      ];
    };

    programs = {
      packages = [
        pkgs.ziplinter
      ];

      runtimes.shell = {
        enable = true;
      };
    };
  };
}
