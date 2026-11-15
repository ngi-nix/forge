{
  config,
  pkgs,
  forge-lib,
  lib,
  ...
}:

let
  app = config.apps.zenroom;
  usageSnippets = forge-lib.snippets.usage app;
in

{
  pkgs.zenroom = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.zenroom;
    };
  };
  apps.zenroom = {
    displayName = "Zenroom";
    description = "No-code cryptographic virtual machine.";
    categories = with forge-lib.categories; [ Development ];

    data = {
      arrayGenerator = ./test/arrayGenerator.zen;
    };

    usage = ''
      Zenroom is a tiny and portable virtual machine that integrates in any application to authenticate and restrict access to data and execute human-readable smart contracts.

      #### Basic Usage

      First, write the following script into a local file (e.g. `${app.data.arrayGenerator.name}`):

      ```
      ${app.data.arrayGenerator}
      ```

      Then, ${usageSnippets.run-shell} and execute the script:

      ```bash
      zenroom -z ${app.data.arrayGenerator.name} | tee myFirstRandomArray.json
      ```

      The result should be printed in the terminal and also in the `myFirstRandomArray.json` file.

      For explanations on the Zencode script syntax and more advanced examples, please refer to the [project documentation](https://dev.zenroom.org).
    '';

    links = {
      website = "https://zenroom.org";
      source = "https://github.com/dyne/Zenroom";
      docs = "https://dev.zenroom.org";
    };

    ngi.grants = {
      Review = [
        "Zenroom-oqs"
      ];
    };

    programs = {
      mainPackage = pkgs.zenroom;
      packages = [ pkgs.zenroom ];

      runtimes.shell.enable = true;
      runtimes.browser = {
        enable = true;
        wasmPackage =
          let
            wasi = pkgs.pkgsCross.wasi32.pkgsOriginal;
          in
          (wasi.zenroom.override { readline = null; }).overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./wasi.patch ];
            # WASI has no `readline`.
            postPatch = old.postPatch + ''
              substituteInPlace build/posix.mk --replace-fail ' -lreadline' '''
            '';
            buildInputs = [ ];
            # Build only the command-line program, not the library.
            buildFlags = [ ];
            preBuild = ''
              # The Lua makefile uses `ar` and `ranlib` from `PATH`.
              mkdir -p $TMPDIR/bin
              ln -s $(command -v $AR) $TMPDIR/bin/ar
              ln -s $(command -v $RANLIB) $TMPDIR/bin/ranlib
              export PATH=$TMPDIR/bin:$PATH
              buildFlagsArray+=(
                VERSION=${old.version} COMMIT=0000000 BRANCH=master CURRENT_YEAR=1970
                -f build/posix.mk deps zenroom
                "cc=$CC" "cxx=$CXX" "ar=$(command -v $AR)" "ranlib=$RANLIB" ARCH=wasm32
              )
            '';
            env = old.env // {
              NIX_CFLAGS_COMPILE = toString [
                # Longfellow-zk uses the WebAssembly SIMD instructions.
                "-msimd128"
                "-DDISABLE_FORK"
                "-D_WASI_EMULATED_PROCESS_CLOCKS"
                "-D_WASI_EMULATED_SIGNAL"
                # Lua uses `setjmp` and `longjmp` for errors.
                # On WebAssembly, these use the exception instructions.
                "-mllvm"
                "-wasm-enable-sjlj"
                "-mllvm"
                "-wasm-use-legacy-eh=false"
                # WASI has no `system` and no `tmpnam`.
                "-Dl_system(cmd)=-1"
                "-DLUA_TMPNAMBUFSIZE=32"
                "-Dlua_tmpnam(b,e)=e=1"
              ];
              NIX_LDFLAGS = toString [
                # Remove the names of the functions, which are half of the size.
                "--strip-all"
                "-lwasi-emulated-process-clocks"
                "-lwasi-emulated-signal"
                "-lsetjmp"
              ];
            };
            # The tests do not run on the build platform.
            doCheck = false;
            preInstall = "";
            postInstall = "";
            installPhase = ''
              runHook preInstall
              install -D zenroom $out/bin/zenroom.wasm
              runHook postInstall
            '';
            meta = old.meta // {
              platforms = lib.platforms.wasi;
            };
          });
        args = "-z ${app.data.arrayGenerator.name}";
        files.${app.data.arrayGenerator.name} = app.data.arrayGenerator.path;
      };
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      zenroom -z ${app.data.arrayGenerator.path}
    '';
  };
}
