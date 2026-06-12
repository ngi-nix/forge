{
  pkgs,
  ...
}:

{
  apps.slipshow = {
    displayName = "Slipshow";
    description = "Innovative presentation tool that moves away from the traditional slide-based approach.";
    usage = ''
      Slipshow is a presentation engine that uses a continuous scrolling canvas
      instead of discrete slides, allowing for more flexible and dynamic presentations.

      Compile a Slipshow presentation to HTML

      ```bash
      slipshow compile presentation.md
      ```

      Start a live preview server

      ```bash
      slipshow serve presentation.md
      ```
    '';

    icon = ./icon.svg;

    links = {
      docs = "https://docs.slipshow.org/en/stable/";
      source = "https://github.com/panglesd/slipshow";
      website = "https://slipshow.org/";
    };

    ngi.grants = {
      Commons = [
        "Slipshow"
      ];
    };

    programs = {
      packages = [
        pkgs.slipshow
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      echo "# Hello" > presentation.md
      slipshow compile presentation.md
    '';
  };
}
