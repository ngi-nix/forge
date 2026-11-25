{
  lib,
  pkgs,
  ...
}:

let
  rustSrc = pkgs.fetchurl {
    url = "https://github.com/esp-rs/rust-build/releases/download/v1.79.0.0/rust-src-1.79.0.0.tar.xz";
    hash = "sha256-/QTEI3h7l1dx4VyGiDjOhQCwW7l6FbpYB5RF2g/Uz0E=";
  };
in
{
  pkgs.rust-esp = {
    version = "1.79.0.0";
    description = "Espressif Rust toolchain with Xtensa architecture support.";
    homePage = "https://github.com/esp-rs/rust-build";
    mainProgram = "rustc";
    license = with lib.licenses; [
      asl20
      mit
    ];

    source = {
      url = "https://github.com/esp-rs/rust-build/releases/download/v1.79.0.0/rust-1.79.0.0-x86_64-unknown-linux-gnu.tar.xz";
      hash = "sha256-xfxl2OZSTi+zizE2aabV2+eUWhrMS4vsgn3kQEANyfc=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
      packages.run = [
        pkgs.libz
        pkgs.stdenv.cc.cc.lib
      ];
    };

    build.extraAttrs = {
      dontBuild = true;
      dontStrip = true;

      installPhase = ''
        mkdir -p $out
        patchShebangs install.sh
        ./install.sh \
          --destdir=$out \
          --prefix="" \
          --without=rust-docs-json-preview,rust-docs \
          --disable-ldconfig

        tar -xf ${rustSrc} -C .
        cp -r rust-src-nightly/rust-src/lib/rustlib/src $out/lib/rustlib/

        rm -f $out/lib/rustlib/uninstall.sh $out/lib/rustlib/install.log

        mv $out/bin/cargo $out/bin/.cargo-real
        cat << 'EOF' > $out/bin/cargo
        #!${pkgs.runtimeShell}
        if [ "$1" = "+esp" ]; then
          shift
        fi
        export RUSTC="''${RUSTC:-@out@/bin/rustc}"
        exec @out@/bin/.cargo-real "$@"
        EOF
        substituteAllInPlace $out/bin/cargo
        chmod +x $out/bin/cargo
      '';
    };

    test.script = ''
      rustc --version | grep "1.79.0"
      cargo --version
      cargo +esp --version
      rustc --print target-list | grep "xtensa-esp32-none-elf"
      test -d "$(rustc --print sysroot)/lib/rustlib/src/rust/library/core"
    '';
  };
}
