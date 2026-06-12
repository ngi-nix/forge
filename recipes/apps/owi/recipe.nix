{
  pkgs,
  ...
}:

{
  apps.owi = {
    displayName = "owi";
    description = "Cross-language symbolic execution for C, C++, Rust, Zig, and Wasm.";
    usage = ''
      owi is a symbolic execution tool for WebAssembly and C, C++, Rust and Zig
      programs compiled to Wasm. It can find bugs and verify program properties.

      Run symbolic execution on a C file

      ```bash
      owi c file.c
      ```

      Run symbolic execution on a Wasm file

      ```bash
      owi sym file.wasm
      ```
    '';

    links = {
      website = "https://ocamlpro.github.io/owi/";
      docs = "https://ocamlpro.github.io/owi/manpages/owi.html";
      source = "https://github.com/ocamlpro/owi";
    };

    ngi.grants = {
      Commons = [
        "Owi-2"
      ];
      Core = [
        "OWI"
      ];
    };

    programs = {
      packages = [
        pkgs.owi
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      cat <<EOF > file.c
      #include <assert.h>
      int main() {
        assert(1 == 1);
        return 0;
      }
      EOF
      owi c file.c
    '';
  };
}
