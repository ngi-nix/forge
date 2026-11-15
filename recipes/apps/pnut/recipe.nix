{
  forge-lib,
  lib,
  pkgs,
  ...
}:
{
  apps.pnut = {
    displayName = "Pnut";
    description = "C to POSIX shell transpiler for reproducible and auditable bootstrapping of GCC from a minimal seed.";
    categories = with forge-lib.categories; [
      Security
    ];
    usage = ''
      Pnut transpiles C source code to POSIX shell scripts, enabling
      reproducible and auditable bootstrapping of GCC from a minimal seed.

      #### Transpile a C file to shell

      ```bash
      pnut input.c > output.sh
      chmod +x output.sh
      ```

      #### Bootstrap pnut itself

      ```bash
      pnut pnut.c > pnut-bootstrap.sh
      chmod +x pnut-bootstrap.sh
      ```
    '';

    links = {
      website = "https://pnut.sh";
      source = "https://github.com/udem-dlteam/pnut";
    };

    ngi.grants = {
      Commons = [
        "Pnut"
        "Pnut-architectures"
      ];
    };

    programs = {
      packages = [
        pkgs.pnut
      ];

      runtimes.shell.enable = true;
      runtimes.browser = {
        enable = true;
        wasmPackage =
          let
            wasi = pkgs.pkgsCross.wasi32.pkgsOriginal;
          in
          wasi.pnut.overrideAttrs (old: {
            # `make install` runs `pnut` to make `pnut-sh.sh`,
            # but `pnut` does not run on the build platform.
            buildFlags = [ "pnut-sh" ];
            installPhase = ''
              runHook preInstall
              install -D build/pnut-sh $out/bin/pnut.wasm
              runHook postInstall
            '';
            # The tests do not run on the build platform.
            doCheck = false;
            meta = old.meta // {
              platforms = lib.platforms.wasi;
            };
          });
        args = "fib.c";
        files."fib.c" = "${pkgs.pnut.src}/examples/fib.c";
      };
    };
  };
}
