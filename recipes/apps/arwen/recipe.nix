{
  config,
  pkgs,
  ...
}:

let
  app = config.apps.arwen;
in

{
  pkgs.arwen = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.arwen;
    };
  };

  pkgs.python3-py-arwen = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.python3.pkgs.py-arwen;
    };
  };

  apps.arwen = {
    displayName = "Arwen";
    description = "Cross-platform patching of shared libraries (ELF and Mach-O).";
    longDescription = ''
      Arwen is a command-line utility for patching ELF files (Linux, BSD) and
      Mach-O files (macOS, iOS).

      It's a Rust-based alternative to patchelf and install_name_tool.
    '';
    usage = ''
      First, [launch the shell envrionment](app/${app.name}#run-shell) containing `${app.name}`.

      Next, get an executable you want to patch.
      For the examples below, we will be using the project itself:

      ```bash
      nix build github:ngi-nix/forge#pkgs.arwen
      cp ./result/bin/arwen ./arwen
      chmod +w ./arwen
      ```

      ##### ELF files

      Print the rpath:

      ```bash
      arwen elf print-rpath ./arwen
      ```

      Set the rpath:

      ```bash
      OLD_RPATH="$(arwen elf print-rpath ./arwen)" # saved for later
      GCC_PATH="$(nix build github:ngi-nix/forge#pkgs.arwen.stdenv.cc.cc.lib --print-out-paths)"

      arwen elf set-rpath "$GCC_PATH/lib" ./arwen
      arwen elf print-rpath ./arwen
      ```

      Remove unused library directories:

      ```bash
      arwen elf shrink-rpath ./arwen
      arwen elf print-rpath ./arwen
      ```

      Restore the original rpath:

      ```bash
      arwen elf set-rpath "$OLD_RPATH" ./arwen
      ```

      ##### Mach-O files

      Add an rpath:

      ```bash
      arwen macho add-rpath /path/to/lib ./arwen
      ```

      Change an existing rpath:

      ```
      arwen macho change-rpath /old/path /new/path ./arwen
      ```

      Change library install name:

      ```bash
      arwen macho change-install-name /old/libname.dylib /new/libname.dylib ./arwen
      ```

      For more details and examples, please see the [project documentation](${config.apps.emerge.links.docs}) page.
    '';

    ngi.grants = {
      Entrust = [
        "ELF-rusttools"
      ];
    };

    links = {
      source = "https://github.com/nichmor/arwen";
      website = "https://nichmor.github.io/arwen";
      docs = "https://github.com/nichmor/arwen#usage";
    };

    programs = {
      mainPackage = pkgs.arwen;
      packages = [
        pkgs.arwen
        (pkgs.python3.withPackages (ps: [
          pkgs.python3-py-arwen
        ]))
      ];

      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
