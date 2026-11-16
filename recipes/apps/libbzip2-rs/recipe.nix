{
  forge-lib,
  lib,
  pkgs,
  ...
}:
{
  pkgs.libbzip2-rs = {
    version = "0.2.6";
    description = "Pure Rust implementation of the bzip2 compression format.";
    homePage = "https://github.com/trifectatechfoundation/libbzip2-rs";
    mainProgram = "bzip2";
    license = lib.licenses.bzip2;

    source = {
      git = "github:trifectatechfoundation/libbzip2-rs/v0.2.6";
      hash = "sha256-bfdzVMfKhn2Cd6kItDTxkn0zgdcWSU7LNRXoKp1fv18=";
    };

    build = {
      builders.rust = {
        enable = true;
        cargoHash = "sha256-33V/iiIjJ4yYvb2+ZYEn36HgsEi2eqrcuKTCpXQaIaU=";
      };
      # The sandbox does not let the tests set the setuid and setgid bits.
      extraAttrs.checkFlags = [
        "--skip=compress_command::output_clears_setuid_and_setgid"
        "--skip=decompress_command::output_clears_setuid_and_setgid"
      ];
    };

    test.script = ''
      cp --no-preserve=mode ${pkgs.libbzip2-rs.src}/bzip2.txt .
      bzip2 -k bzip2.txt
      bzip2 -t bzip2.txt.bz2
      bzip2 -dc bzip2.txt.bz2 | cmp - bzip2.txt
    '';
  };

  apps.libbzip2-rs = {
    displayName = "libbzip2-rs";
    description = "Compress and decompress files in the bzip2 format, with a memory-safe Rust implementation.";
    categories = with forge-lib.categories; [ Development ];
    usage = ''
      libbzip2-rs is a Rust implementation of bzip2.
      Its `bzip2` program has the same options as the original `bzip2` program.

      Compress a file and keep the original file

      ```bash
      bzip2 -k file.txt
      ```

      Decompress a file

      ```bash
      bzip2 -d file.txt.bz2
      ```

      Test the integrity of a compressed file

      ```bash
      bzip2 -t file.txt.bz2
      ```
    '';

    links = {
      source = "https://github.com/trifectatechfoundation/libbzip2-rs";
      website = "https://trifectatech.org/initiatives/data-compression/";
    };

    ngi.grants = {
      Core = [ "ZipLinting" ];
    };

    programs = {
      packages = [ pkgs.libbzip2-rs ];
      runtimes.shell.enable = true;
      runtimes.browser = {
        enable = true;
        wasmPackage =
          let
            wasi = pkgs.pkgsCross.wasi32.pkgsOriginal;
          in
          wasi.rustPlatform.buildRustPackage {
            inherit (pkgs.libbzip2-rs)
              pname
              version
              src
              cargoDeps
              ;
            patches = [ ./wasi.patch ];
            # The tests do not run on the build platform.
            doCheck = false;
            # Link with the C compiler of the WASI toolchain, not with `rust-lld`.
            env.RUSTFLAGS = "-Clinker-flavor=gcc -Clink-self-contained=no -Clink-arg=--target=${wasi.stdenv.targetPlatform.config}";
            meta.mainProgram = "bzip2";
          };
        args = "-kv bzip2.txt";
        files."bzip2.txt" = "${pkgs.libbzip2-rs.src}/bzip2.txt";
      };
    };
  };
}
