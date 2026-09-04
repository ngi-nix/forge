{
  description = "Forge presentations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            reveal-md
            chromium
          ];

          shellHook = ''
            echo "Reveal.js presentation environment loaded!"
            echo ""
            echo "Available commands:"
            echo "  reveal-md <dir>/presentation.md -w        # Run presentation with live reload"
            echo "  reveal-md <dir>/presentation.md --print-size A4 --print <dir>/presentation.pdf --puppeteer-chromium-executable \$(which chromium)  # Export to PDF"
            echo ""
            echo "Example:"
            echo "  reveal-md nixcon-2026/presentation.md -w"
          '';
        };
      }
    );
}
