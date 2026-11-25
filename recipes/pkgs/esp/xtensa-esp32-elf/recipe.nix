{
  lib,
  pkgs,
  config,
  ...
}:

{
  pkgs.xtensa-esp32-elf = {
    version = "11.2.0-esp-2022r1";
    description = "Espressif Xtensa ESP32 GCC toolchain.";
    homePage = "https://github.com/espressif/crosstool-NG";
    mainProgram = "xtensa-esp32-elf-gcc";
    license = lib.licenses.gpl3Plus;

    source = {
      url = "https://github.com/espressif/crosstool-NG/releases/download/esp-2022r1/xtensa-esp32-elf-gcc11_2_0-esp-2022r1-linux-amd64.tar.xz";
      hash = "sha256-aY2EB+GCddGP630a/baIALl5BPvjkIBCL7hgmvpJ3zA=";
    };

    build.builders.standard = {
      enable = true;
      packages.build = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.patchelfUnstable # patchelf < 0.19 corrupts ELF headers with 2MB page size
        pkgs.autoPatchelfHook
      ];
      packages.run = [
        pkgs.libz
        pkgs.stdenv.cc.cc.lib
      ];
    };

    build.phases = {
      build.enable = false;

      install.script.main = ''
        mkdir -p $out
        cp -a . $out/
      '';
    };

    build.extraAttrs = {
      # Pre-built binaries crash if stripped
      dontStrip = true;
      # Disable Nix's default patching to prevent breaking the binary
      dontPatchELF = true;

      # Espressif binaries require 2MB page size (2097152 bytes) or they crash on launch
      patchelfFlags = [
        "--page-size"
        "2097152"
      ];

      autoPatchelfIgnoreMissingDeps = [
        "libpython2.7.so.1.0"
      ];
    };

    test.script = ''
      xtensa-esp32-elf-gcc --version | grep "11.2.0"
      xtensa-esp32-elf-gcc -dumpmachine | grep "xtensa-esp32-elf"
      xtensa-esp32-elf-g++ --version
      xtensa-esp32-elf-as --version
      xtensa-esp32-elf-ar --version
      xtensa-esp32-elf-ld --version
      xtensa-esp32-elf-objcopy --version
      xtensa-esp32-elf-objdump --version
      echo 'int main(void) { return 0; }' | xtensa-esp32-elf-gcc -x c -c - -o /dev/null
    '';
  };
}
