{
  lib,
  pkgs,
  ...
}:

{
  pkgs.esp-idf = {
    version = "5.0.1";
    description = "Espressif IoT Development Framework.";
    homePage = "https://github.com/espressif/esp-idf";
    license = lib.licenses.asl20;

    source = {
      url = "https://github.com/espressif/esp-idf/releases/download/v5.0.1/esp-idf-v5.0.1.zip";
      hash = "sha256-oLChdDydel7b18lEdOcqxChBqj5fGpRvQ4mOH218TTc=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = [
        pkgs.unzip
      ];
    };

    build.extraAttrs = {
      dontBuild = true;
      dontStrip = true;

      installPhase = ''
        mkdir -p $out
        cp -a . $out/

        mkdir -p $out/nix-support
        cat << 'EOF' > $out/nix-support/setup-hook
        export IDF_PATH=@out@
        EOF
        substituteAllInPlace $out/nix-support/setup-hook
      '';
    };

    test.script = ''
      test -f "$IDF_PATH/tools/cmake/project.cmake"
      test -f "$IDF_PATH/tools/cmake/toolchain-esp32.cmake"
      test -f "$IDF_PATH/components/esp_wifi/include/esp_wifi.h"
      test -f "$IDF_PATH/components/esp_wifi/lib/esp32/libcore.a"
      test -f "$IDF_PATH/components/mbedtls/mbedtls/library/aes.c"
      test -d "$IDF_PATH/components/freertos"
    '';
  };
}
