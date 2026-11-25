{
  lib,
  pkgs,
  config,
  ...
}:

{
  pkgs.esp-clang = {
    version = "21.1.3_20260408";
    description = "ESP-Clang toolchain for Espressif SoCs.";
    homePage = "https://github.com/espressif/llvm-project";
    mainProgram = "clang";
    license = lib.licenses.asl20;

    source = {
      url = "https://github.com/espressif/llvm-project/releases/download/esp-${config.pkgs.esp-clang.version}/clang-esp-${config.pkgs.esp-clang.version}-x86_64-linux-gnu.tar.xz";
      hash = "sha256-bmK/GXO1e1OIqtKBzhRj6VPnCz2N9070Zoxw8x++2mM=";
    };

    build.builders.standard = {
      enable = true;
      packages.build = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
      packages.run = [
        pkgs.libxml2
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

    test.script = ''
      clang --version | grep "Espressif clang"
      xtensa-esp32-elf-clang-as --version
      riscv32-esp-elf-clang-as --version
    '';
  };
}
