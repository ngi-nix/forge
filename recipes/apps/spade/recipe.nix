{
  pkgs,
  ...
}:

{
  apps.spade = {
    displayName = "Spade";
    description = "Standalone hardware description language.";
    usage = ''
      Spade is a hardware description language (HDL) with a Rust-inspired syntax,
      designed for safety and expressiveness in hardware design.

      #### Example

      Initialize a new Spade project using the Swim build tool

      ```
      swim init my_project
      cd my_project
      ```

      Build the project

      ```
      swim build
      ```
    '';

    links = {
      website = "https://spade-lang.org";
      docs = "https://docs.spade-lang.org";
      source = "https://gitlab.com/spade-lang/spade";
    };

    ngi.grants = {
      Core = [
        "Spade"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.spade
        pkgs.swim
      ];

      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      spade --help
      echo "entity main() -> bool { true }" > main.spade
      spade -o main.mir main.spade
      test -f main.mir
    '';
  };
}
