{
  pkgs,
  ...
}:

{
  apps.cpdf = {
    displayName = "cpdf";
    description = "Command-line PDF manipulation tool.";
    usage = ''
      The `cpdf` toolkit is able to merge, split, encrypt, decrypt, and manipulate PDF files.

      For more examples and information, please see the [User Manual](https://www.coherentpdf.com/cpdfmanual.pdf).

      #### Basic Usage

      Extract a page range

      ```bash
      cpdf document.pdf 3-7 -o range.pdf
      ```

      Merge two PDFs

      ```bash
      cpdf -merge input1.pdf input2.pdf -o merged.pdf
      ```

      Split a PDF into single pages

      ```bash
      cpdf -split document.pdf -o split-page-%%%.pdf
      ```

      Split a PDF into page chunks

      ```bash
      cpdf -split document.pdf -o page-chunk-%%%.pdf -chunk 10
      ```

      Add a watermark

      ```bash
      cpdf document.pdf -stamp-on watermark.pdf -o stamped.pdf
      ```

      #### Compression

      Compress a PDF

      ```bash
      cpdf -compress document.pdf -o compressed.pdf
      ```

      Decompress a PDF

      ```bash
      cpdf -decompress compressed.pdf -o decompressed.pdf
      ```

      #### Encryption

      Encrypt a PDF with a password

      ```bash
      cpdf document.pdf -encrypt AES256ISO username password -o encrypted.pdf
      ```

      Decrypt a PDF

      ```bash
      cpdf encrypted.pdf -decrypt owner=username -o decrypted.pdf
      ```
    '';

    icon = ./icon.svg;

    links = {
      website = "https://coherentpdf.com/cpdf";
      source = "https://github.com/johnwhitington/cpdf-source";
      docs = "https://www.coherentpdf.com/cpdfmanual.pdf";
    };

    ngi.grants = {
      Commons = [
        "Cpdf-redaction"
      ];
      Entrust = [
        "cPDF-UA"
      ];
    };

    programs = {
      mainPackage = pkgs.ocamlPackages.cpdf;
      packages = with pkgs; [ ocamlPackages.cpdf ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    test.programs.script = ''
      CPDF_PATH="${pkgs.ocamlPackages.cpdf}"
      INPUT_PDF="$CPDF_PATH/share/doc/cpdf/cpdfmanual.pdf"

      cpdf -version 2>&1 | grep -q "cpdf"

      cpdf -list-bookmarks "$INPUT_PDF" 2>&1 > /dev/null

      cpdf "$INPUT_PDF" 3-7 -o range1.pdf
      cpdf "$INPUT_PDF" 8-10 -o range2.pdf

      cpdf -merge range1.pdf range2.pdf -o output.pdf

      cpdf output.pdf -compress -o compressed.pdf
      cpdf compressed.pdf -encrypt AES256ISO username password -o encrypted.pdf

      cpdf encrypted.pdf -decrypt owner=username -o decrypted.pdf
      cpdf decrypted.pdf -decompress -o decompressed.pdf
    '';
  };
}
