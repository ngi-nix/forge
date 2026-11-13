{
  config,
  lib,
  ...
}:
{
  options = {
    program = {
      enable = lib.mkEnableOption ''
        Program runtime
      '';
    };
    shell = {
      enable = lib.mkEnableOption ''
        Shell runtime
      '';
    };
    browser = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Browser runtime.

          The browser runtime opens the _shell_ runtime packages in an x86_64
          Linux virtual machine in the web browser.
          If `wasmPackage` is set, the browser also runs this package natively.

          Enable this option only for CLI programs,
          because the virtual machine has no display and no network.
        '';
      };
      wasmPackage = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = ''
          WASI build of the program that the browser runs natively.
          The package must contain `bin/<meta.mainProgram>.wasm`.

          Use `pkgs.pkgsCross.wasi32.pkgsOriginal` for the Nixpkgs packages:
          in `pkgs.pkgsCross.wasi32`, the Forge packages are not cross-compiled.
        '';
        example = lib.literalExpression "pkgs.pkgsCross.wasi32.pkgsOriginal.hello";
      };
      wasmProgram = lib.mkOption {
        type = lib.types.str;
        internal = true;
        readOnly = true;
        default = config.browser.wasmPackage.meta.mainProgram or "";
        defaultText = lib.literalExpression ''config.programs.runtimes.browser.wasmPackage.meta.mainProgram or ""'';
        description = "Name of the WASI program in `bin/` of `wasmPackage`, without the `.wasm` suffix.";
      };
      args = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Example arguments for the WASI program.
          The browser shows them before the user runs the program.

          The browser splits the arguments as POSIX shell words
          (like Python `shlex.split`): with whitespace, single quotes,
          double quotes and backslashes.
          It does not expand variables, globs or `~`.
        '';
        example = "-c '.a | map(. * 2)'";
      };
      stdin = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Example standard input for the WASI program.
          The browser shows it before the user runs the program.
        '';
        example = ''{"a": [1, 2]}'';
      };
    };
  };
}
