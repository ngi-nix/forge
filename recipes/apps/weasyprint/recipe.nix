{
  pkgs,
  ...
}:

{
  apps.weasyprint = {
    displayName = "WeasyPrint";
    description = "Print rendering engine for HTML and CSS.";
    usage = ''
      WeasyPrint converts HTML and CSS documents into PDF files.

      #### Example

      Convert an HTML file to PDF

      ```
      weasyprint input.html output.pdf
      ```

      Convert a URL to PDF

      ```
      weasyprint https://example.com output.pdf
      ```

      Specify a base URL for resolving relative assets

      ```
      weasyprint --base-url . input.html output.pdf
      ```
    '';

    links = {
      website = "https://weasyprint.org";
      source = "https://github.com/Kozea/WeasyPrint";
    };

    ngi.grants = {
      Core = [
        "WeasyPrint"
      ];
    };

    programs = {
      packages = [
        pkgs.python3Packages.weasyprint
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs = {
      packages = [ pkgs.file ];
      script = ''
        echo "<html><body><h1>test</h1></body></html>" > /tmp/test.html
        export HOME=$(mktemp -d)
        weasyprint /tmp/test.html /tmp/output.pdf
        file /tmp/output.pdf | grep -q "PDF"
      '';
    };
  };
}
