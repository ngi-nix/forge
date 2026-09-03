{
  pkgs,
  config,
  lib,
  ...
}:
let
  recipe = config.apps.typst;
in
{
  pkgs.typst = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.typst;
    };
  };

  apps.typst = {
    displayName = "Typst";
    description = "New markup-based typesetting system that is powerful and easy to learn.";
    usage = ''
        Typst is a markup-based typesetting system, combining plain-text writing
      with built-in styling, math, and scripting to produce typeset documents
      without the complexity of LaTeX.

      Compile a document to PDF

      ```bash
      typst compile document.typ
      ```

      A sample document is bundled for a quick first try

      ```
      ${recipe.data.sampleDoc}
      ```

      Compile the sample document to PDF

      ```bash
      typst compile ${recipe.data.sampleDoc.path} ${lib.removeSuffix ".typ" recipe.data.sampleDoc.name}.pdf
      ```

      Watch a document and recompile automatically on changes

      ```bash
      typst watch document.typ
      ```

      Create a new project from a template

      ```bash
      typst init @preview/basic-report
      ```
    '';

    links = {
      website = "https://typst.app";
      source = "https://github.com/typst/typst";
      docs = "https://typst.app/docs";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Typst-Accessibility"
        "Mobile-Typst-editor"
      ];
      Core = [
        "Typst-HTML"
      ];
    };

    data = {
      sampleDoc = ./sample.typ;
      referenceImage = ./reference.png;
    };

    programs = {
      mainPackage = pkgs.typst;
      packages = [ pkgs.typst ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs = {
      packages = [
        pkgs.poppler-utils
        pkgs.imagemagick
      ];

      script = ''
        typst compile ${recipe.data.sampleDoc.path} new.pdf
        pdftoppm -png -r 150 new.pdf new
        magick compare -metric RMSE -fuzz 1% ${recipe.data.referenceImage.path} new-1.png null:
      '';
    };
  };
}
