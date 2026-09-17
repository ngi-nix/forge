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
      packages.build = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
      packages.run = [
        pkgs.libusb1
        pkgs.libz
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.systemd ];
    };

    build.extraAttrs = {
      dontBuild = true;

      installPhase = ''
        mkdir -p $out
        cp -a . $out/
      '';
    };

    test.script = ''
      openocd --version
    '';
  };
}
