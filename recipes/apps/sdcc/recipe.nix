{
  pkgs,
  config,
  lib,
  ...
}:
let
  recipe = config.apps.sdcc;
in
{
  pkgs.sdcc = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.sdcc;
    };
  };

  apps.sdcc = {
    displayName = "SDCC";
    description = "Retargettable, optimizing Standard C compiler suite for embedded microcontrollers.";
    categories = with lib.categories; [ Development ];
    usage = ''
      SDCC is a retargettable, optimizing C compiler suite (supporting C89,
      C99, C11, and C23) targeting embedded microcontrollers, including Intel
      MCS51-based MCUs (8051 and variants), Zilog Z80-based MCUs, STMicroelectronics
      STM8, Freescale HC08, MOS 6502/WDC 65C02, and others. The suite also
      includes an assembler/linker, preprocessor, simulator, and source-level
      debugger.

      #### Basic usage:

      ```bash
      sdcc <source-file> -o <output-hex>
      ```

      Compile a sample C source file for the default target (8051)

      ```bash
      sdcc ${recipe.data.main.path} -o ${lib.removeSuffix ".c" recipe.data.main.name}.ihx
      ```

      Compile for a different target, for example STM8

      ```bash
      sdcc -mstm8 ${recipe.data.main.path} -o ${lib.removeSuffix ".c" recipe.data.main.name}.ihx
      ```
    '';

    links = {
      website = "https://sdcc.sourceforge.net";
      source = "https://sourceforge.net/p/sdcc/git-mirror/ci/trunk/tree";
      docs = "https://sourceforge.net/p/sdcc/wiki/Home";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "SDCC-C23"
      ];
      Entrust = [
        "SDCC"
      ];
    };

    data = {
      main = ./main.c;
    };

    programs = {
      packages = [ pkgs.sdcc ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      sdcc ${recipe.data.main.path} -o ${lib.removeSuffix ".c" recipe.data.main.name}.ihx
    '';
  };
}
