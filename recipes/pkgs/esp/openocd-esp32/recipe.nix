{
  lib,
  pkgs,
  config,
  ...
}:

{
  pkgs.openocd-esp32 = {
    version = "0.12.0-esp32-20260703";
    description = "ESP-IDF OpenOCD tool for Espressif SoCs.";
    homePage = "https://github.com/espressif/openocd-esp32";
    mainProgram = "openocd";
    license = lib.licenses.gpl2Plus;

    source = {
      url = "https://github.com/espressif/openocd-esp32/releases/download/v${config.pkgs.openocd-esp32.version}/openocd-esp32-linux-amd64-${config.pkgs.openocd-esp32.version}.tar.gz";
      hash = "sha256-S3HRtNjkAlApRm54AWEmKgQTc0i2jpZcFSUNvuvvA84=";
    };

    build.standardBuilder = {
      enable = true;
      packages.build = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.patchelf ];
      packages.run = [
        pkgs.libusb1
        pkgs.libz
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.udev ];
    };

    build.extraAttrs = {
      dontBuild = true;
      dontStrip = true;
      dontPatchELF = true;

      installPhase = ''
        mkdir -p $out
        cp -a . $out/
      '';

      postFixup = lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        patchelf \
          --page-size 2097152 \
          --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" \
          --set-rpath "${
            lib.makeLibraryPath [
              pkgs.udev
              pkgs.libusb1
              pkgs.libz
            ]
          }" \
          $out/bin/openocd
      '';
    };

    test.script = ''
      openocd --version
    '';
  };
}
