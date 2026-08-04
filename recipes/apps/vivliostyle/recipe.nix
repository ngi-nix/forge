{
  pkgs,
  ...
}:

{
  apps.vivliostyle = {
    displayName = "Vivliostyle";
    description = "CSS typesetting ecosystem for creating beautifully formatted documents using web technologies.";
    usage = ''
      Vivliostyle is a CSS typesetting ecosystem for creating beautifully formatted documents.

      #### Basic Usage

      First, [enter the Nix shell](app/vivliostyle#run-shell), then scaffold a new project:

      ```bash
      vivliostyle create ./my-project
      ```

      You'll be prompted to choose a project template, among other options.

      Once the project is created, move into it:

      ```bash
      cd my-project
      ```

      Then, typeset and build your document:

      ```bash
      vivliostyle build -s A4 -o my-document.pdf
      ```

      Which produces a PDF file that you can open it with your favorite PDF viewer.

      To preview the document using the bundled browser without building, you can also run:

      ```bash
      vivliostyle preview
      ```
    '';

    icon = ./icon.svg;

    links = {
      website = "https://vivliostyle.org";
      source = "https://github.com/vivliostyle/vivliostyle-cli";
      docs = "https://vivliostyle.org/docs";
    };

    ngi.grants = {
      Commons = [
        "Vivliostyle"
      ];
    };

    programs = {
      mainPackage = pkgs.vivliostyle;
      packages = with pkgs; [ vivliostyle ];

      runtimes.shell.enable = true;
      runtimes.program.enable = true;
    };
  };
}
