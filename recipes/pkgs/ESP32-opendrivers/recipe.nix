{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "esp32-open-mac";
  version = "0-unstable-2026";

  description = "Open-source bare-metal Wi-Fi MAC layer and networking stack for ESP32 devices";
  homePage = "https://esp32-open-mac.be/";
  license = lib.licenses.gpl3Only;

 source = {
  git = "github:esp32-open-mac/esp32-open-mac/20ce43d595be914b4d3f553b28352bc07e003fa1";
  hash = "sha256-NCCLJW1W9ycADjKx7ObrHsvMuPfmar9hjJuBUcznfSI=";
};

  build.standardBuilder = {
    enable = true;

    packages.build = with pkgs; [
      cmake
      ninja
      python3
      git
      gnumake
      rustup
      cargo
      rustc
      espup
    ];
  };

  build.extraAttrs = {
    postPatch = ''
      echo "Packaging notes:"
      echo "- Build system: ESP-IDF v5.0.1"
      echo "- Rust toolchain: cargo +esp"
      echo "- Rust target: xtensa-esp32-none-elf"
      echo "- Firmware target: ESP32"
    '';

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR

      if ! command -v idf.py >/dev/null 2>&1; then
        echo "ERROR: idf.py not found"
        exit 1
      fi

      idf.py build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/esp32-open-mac

      if [ -d build ]; then
        find build -name "*.bin" -exec cp {} $out/share/esp32-open-mac/ \; || true
        find build -name "*.elf" -exec cp {} $out/share/esp32-open-mac/ \; || true
        find build -name "*.map" -exec cp {} $out/share/esp32-open-mac/ \; || true
      fi

      runHook postInstall
    '';
  };
  test.script = ''
    test -d "$out/share/esp32-open-mac"

    firmware_count=$(find "$out" -name "*.bin" | wc -l)

    if [ "$firmware_count" -eq 0 ]; then
      echo "No firmware images were installed"
      exit 1
    fi
  '';
}