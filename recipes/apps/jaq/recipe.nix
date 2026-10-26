{
  pkgs,
  ...
}:
{
  pkgs.jaq = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.jaq;
    };
  };
  apps.jaq = {
    displayName = "jaq";
    description = "Data wrangling tool focusing on correctness, speed, and simplicity.";
    usage = ''
      jaq is a fast and correct reimplementation of jq for processing JSON, YAML, TOML, XML, and CSV data.

      #### Example

      Extract a field from a JSON file

      ```bash
      jaq '.name' file.json
      ```

      Transform an array

      ```bash
      echo '[1,2,3]' | jaq '[.[] * 2]'
      ```

      Filter objects by condition

      ```bash
      jaq '.[] | select(.age > 30)' data.json
      ```

      Output raw strings without JSON encoding

      ```bash
      jaq -r '.items[].name' data.json
      ```
    '';

    links = {
      docs = "https://gedenkt.at/jaq/manual";
      source = "https://github.com/01mf02/jaq";
    };

    ngi.grants = {
      Commons = [
        "Polyglot-jaq"
      ];
      Entrust = [
        "jaq"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.jaq
      ];

      runtimes.shell.enable = true;

      runtimes.browser = {
        enable = true;
        # TODO: use `pkgs.pkgsCross.wasi32.pkgsOriginal.jaq` when Nixpkgs has
        # https://github.com/NixOS/nixpkgs/pull/578407.
        wasmPackage =
          let
            wasi = pkgs.pkgsCross.wasi32.pkgsOriginal;
          in
          wasi.jaq.overrideAttrs {
            # `fd-lock` (file history) and `mimalloc` do not support WASI.
            # `jaq-play` needs `wasm-bindgen`.
            postPatch = ''
              substituteInPlace jaq/Cargo.toml \
                --replace-fail ', features = ["with-file-history"]' ""
            '';
            cargoBuildNoDefaultFeatures = true;
            # The tests do not run on the build platform.
            doCheck = false;
            cargoBuildFlags = [
              "-p"
              "jaq"
            ];
            # Link with the C compiler of the WASI toolchain, not with `rust-lld`.
            env.RUSTFLAGS = "-Clinker-flavor=gcc -Clink-self-contained=no -Clink-arg=--target=${wasi.stdenv.targetPlatform.config}";
          };
        args = "-c '.a | map(. * 2)'";
        stdin = ''{"a": [1, 2]}'';
      };
    };
  };
}
