{
  forge-lib,
  lib,
  pkgs,
  ...
}:

{
  pkgs.cpdf = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.ocamlPackages.cpdf;
    };
  };
  apps.cpdf = {
    displayName = "cpdf";
    description = "Command-line PDF manipulation tool.";
    categories = with forge-lib.categories; [
      Office
    ];
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
      mainPackage = pkgs.cpdf;
      packages = [ pkgs.cpdf ];

      runtimes.shell.enable = true;
      runtimes.browser = {
        enable = true;
        # `camlpdf` uses C code for zlib, AES and SHA-2.
        # The files in `wasi/` replace this C code with OCaml code,
        # thus `wasm_of_ocaml` can compile `cpdf` for WASI.
        wasmPackage =
          let
            inherit (pkgs.pkgsOriginal) stdenv ocamlPackages;
            inherit (ocamlPackages) camlpdf cpdf;
          in
          stdenv.mkDerivation {
            pname = "cpdf-wasi";
            inherit (cpdf) version;

            dontUnpack = true;

            nativeBuildInputs = with ocamlPackages; [
              ocaml
              findlib
              wasm_of_ocaml-compiler
              pkgs.pkgsOriginal.binaryen
            ];
            buildInputs = with ocamlPackages; [
              checkseum
              decompress
              digestif
            ];

            buildPhase = ''
              runHook preBuild

              # Write the value of a variable of the Makefile in directory `$1`.
              makeVar() {
                printf 'include Makefile\nprint-%%:\n\t@echo $(%s)\n' "$2" | make -s -C "$1" -f - "print-$2"
              }
              camlpdfDir=${camlpdf.src}
              cpdfDir=${cpdf.src}
              pdfMods=$(makeVar $camlpdfDir PDFMODS)
              cpdfMods="$(makeVar $cpdfDir NONDOC) $(makeVar $cpdfDir DOC)"

              mkdir build
              cp $camlpdfDir/*.ml $camlpdfDir/*.mli $cpdfDir/*.ml $cpdfDir/*.mli build/
              chmod -R u+w build
              cp ${./wasi}/*.ml build/
              cd build
              patch -p1 < ${./wasi/crypt.patch}

              files=""
              for m in pdfaes $pdfMods $cpdfMods cpdfcommandrun; do
                if [ -f $m.mli ]; then files="$files $m.mli"; fi
                files="$files $m.ml"
              done
              # `De` refers to `Checkseum`. Select its OCaml implementation, not its C implementation.
              # `-no-check-prims`: `camlpdf` declares C functions that only `js_of_ocaml` uses.
              ocamlfind ocamlc -g -package checkseum.ocaml,unix,decompress.de,digestif.ocaml -linkpkg -no-check-prims $files -o cpdf.bc
              wasm_of_ocaml compile --enable wasi cpdf.bc -o cpdf.js

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              install -D cpdf.assets/code.wasm $out/bin/cpdf.wasm
              runHook postInstall
            '';

            meta = {
              inherit (cpdf.meta) description homepage license;
              mainProgram = "cpdf";
            };
          };
        args = "-add-text 'Made with cpdf in your browser' -top 20 -font-size 24 sample.pdf -o stamped.pdf";
        # `cpdf` does not make the example file, thus `typst` makes it.
        files."sample.pdf" = pkgs.pkgsOriginal.runCommand "cpdf-sample.pdf" {
          nativeBuildInputs = [ pkgs.pkgsOriginal.typst ];
        } "typst compile ${./sample.typ} $out";
      };
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      CPDF_PATH="${pkgs.cpdf}"
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
