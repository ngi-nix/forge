{
  config,
  pkgs,
  ...
}:

{
  pkgs = {
    superbol-studio = {
      description = "Modern development environment for COBOL in VSCode.";
      build.identityBuilder = {
        enable = true;
        derivation = pkgs.pkgsOriginal.vscode-with-extensions.override {
          vscode = pkgs.pkgsOriginal.vscodium.fhsWithPackages (p: [
            p.gcc.cc # For gcov
            (
              if p.stdenv.hostPlatform.isDarwin then p.gnucobol else p.ocamlPackages.superbol-studio-oss.gnucobol
            )
            p.gdb
          ]);
          vscodeExtensions = with pkgs.pkgsOriginal.vscode-extensions; [
            ocamlpro.superbol
            jacqueslucke.gcov-viewer
          ];
        };
      };
    };
  };

  apps.superbol-studio = {
    displayName = "Superbol Studio";
    description = "Modern development environment for COBOL in VSCode.";
    longDescription = ''
      SuperBOL Studio is a modern development environment for COBOL in VSCode.

      It integrates an intelligent code analysis server (LSP) providing navigation, auto-completion and error diagnostics, as well as code coverage visualization to identify executed portions of your programs.
    '';

    usage = ''
      First, [launch the program](app/${config.apps.superbol-studio.name}#run-program).

      To start using the extension on an existing project, open its folder in VS Code (`File > Add Folder to Workspace...`). The extension will start automatically whenever the folder contains files with usual COBOL filename extensions (`.cob`, `.cbl`, `.cpy`, `.cbx`).

      When editing a program, you can press `Ctrl`+`Space` to obtain suggestions on valid keywords, user-defined words (data item or paragraph names), and even complete COBOL sentences. Select an option with the arrow keys, and press `Enter` to insert the selected suggestion.

      For more information, please consult the [project documentation](${config.apps.superbol-studio.links.docs}), the [VSCode Marketplace Entry](https://marketplace.visualstudio.com/items?itemName=OCamlPro.SuperBOL) and the [VSCode Documentation](https://code.visualstudio.com/docs)
    '';

    links = {
      website = "https://superbol.eu/en/";
      docs = "https://superbol.eu/solutions/superbol-studio/user-manual/en/index.html";
      source = "https://github.com/OCamlPro/superbol-studio-oss";
    };

    ngi.grants = {
      Commons = [
        "COBOL-compiler"
      ];
    };

    # Created by the amazing @AhmedAmrNabil
    icon = ./icon.svg;

    programs = {
      mainPackage = pkgs.superbol-studio;
      packages = [
        pkgs.superbol-studio
        pkgs.pkgsOriginal.gcc.cc # For gcov
        pkgs.pkgsOriginal.gdb
        pkgs.pkgsOriginal.ocamlPackages.superbol-studio-oss # The actual lsp binary
        pkgs.pkgsOriginal.ocamlPackages.superbol-studio-oss.gnucobol # Pre-release gnucobol 4 used by superbol
      ];

      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
