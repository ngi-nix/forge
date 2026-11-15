{
  pkgs,
  config,
  forge-lib,
  lib,
  ...
}:
let
  recipe = config.apps.typst;
in
{
  pkgs.typst = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.typst;
    };
  };

  apps.typst = {
    displayName = "Typst";
    description = "New markup-based typesetting system that is powerful and easy to learn.";
    categories = with forge-lib.categories; [ Development ];
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
      runtimes.browser = {
        enable = true;
        wasmPackage =
          let
            wasi = pkgs.pkgsCross.wasi32.pkgsOriginal;
            # TODO: use `wasi.openssl` when Nixpkgs has
            # https://github.com/NixOS/nixpkgs/pull/579168.
            openssl = wasi.openssl.overrideAttrs (old: {
              configureScript = "./Configure linux-generic32";
              configureFlags = old.configureFlags ++ [
                "no-afalgeng"
                "no-apps"
                "no-asm"
                "no-devcryptoeng"
                "no-dso"
                "no-secure-memory"
                "no-sock"
                "no-threads"
                "no-ui-console"
                "-D_WASI_EMULATED_GETPID"
                "-lwasi-emulated-getpid"
              ];
              # `no-apps` removes the `openssl` program,
              # thus there is no `$out/bin` and no `c_rehash` wrapper.
              postInstall = ''
                makeWrapper() { :; }
                mkdir -p $out/bin
              ''
              + old.postInstall;
            });
          in
          (wasi.typst.override { inherit openssl; }).overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./wasi.patch ];
            # The tests do not run on the build platform.
            doCheck = false;
            # Link with the C compiler of the WASI toolchain, not with `rust-lld`.
            env = (old.env or { }) // {
              RUSTFLAGS = "-Clinker-flavor=gcc -Clink-self-contained=no -Clink-arg=--target=${wasi.stdenv.targetPlatform.config}";
            };
          });
        args = "compile sample.typ sample.pdf";
        files."sample.typ" = ./sample.typ;
      };
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
