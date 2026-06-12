{
  pkgs,
  ...
}:

{
  apps.inko = {
    displayName = "Inko";
    description = "Programming language with deterministic automatic memory management.";
    usage = ''
      Inko is a statically typed, safe programming language for building concurrent
      software. It uses deterministic automatic memory management without a garbage
      collector or manual memory management.

      Compile and run an Inko program

      ```bash
      inko run hello.inko
      ```

      Build a project

      ```bash
      inko build
      ```
    '';

    links = {
      website = "https://inko-lang.org/";
      docs = "https://docs.inko-lang.org/manual/main/";
      source = "https://github.com/inko-lang/inko";
    };

    ngi.grants = {
      Entrust = [
        "Inko"
      ];
    };

    programs = {
      packages = [
        pkgs.inko
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      mkdir -p hello/src
      cat <<EOF > hello/src/main.inko
      import std.stdio (Stdout)

      type async Main {
        fn async main {
          Stdout.new.print('Hello, World!')
        }
      }
      EOF
      inko run hello/src/main.inko | grep -q "Hello, World!"
    '';
  };
}
