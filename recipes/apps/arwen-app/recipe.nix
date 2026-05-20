{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "arwen-app";
  displayName = "Arwen";
  description = "Cross-platform patching of shared libraries (ELF and Mach-O).";
  usage = ''
    Arwen is a command-line utility for patching ELF files (Linux, BSD) and
    Mach-O files (macOS, iOS).

    It is a modern, Rust-based alternative to patchelf and install_name_tool.

    #### Examples

    These are a few examples for how to use Arwen.
    For more, please refer to the [project documentation](https://github.com/nichmor/arwen#usage).

    ##### ELF

    Print the rpath:

    ```bash
    arwen elf print-rpath my_binary
    ```

    Set the rpath:

    ```bash
    arwen elf set-rpath /path/to/lib my_binary
    ```

    Remove unused library directories:

    ```bash
    arwen elf shrink-rpath my_binary
    ```

    ##### Mach-O

    Add an rpath:

    ```bash
    arwen macho add-rpath /path/to/lib my_binary
    ```

    Change an existing rpath:

    ```
    arwen macho change-rpath /old/path /new/path my_binary
    ```

    Change library install name:

    ```bash
    arwen macho change-install-name /old/libname.dylib /new/libname.dylib my_binary
    ```
  '';

  ngi.grants = {
    Entrust = [ "ELF-rusttools" ];
  };

  links = {
    source = "https://github.com/nichmor/arwen";
    website = "https://nichmor.github.io/arwen";
  };

  programs = {
    packages = with pkgs; [
      mypkgs.arwen
      (python3.withPackages (ps: [
        mypkgs.py-arwen
      ]))
    ];

    runtimes.shell = {
      enable = true;
    };
  };
}
