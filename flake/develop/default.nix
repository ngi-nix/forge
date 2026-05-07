{ inputs, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:

    let
      formatter = pkgs.callPackage ./formatter.nix { inherit inputs; };
      devShell = pkgs.callPackage ./devshell.nix { inherit inputs formatter; };

      sphinxEnv = pkgs.python3.withPackages (
        ps: with ps; [
          linkify-it-py
          sphinx
          myst-parser
          sphinx-book-theme
          sphinx-copybutton
          sphinx-design
          sphinx-sitemap
          sphinx-notfound-page
        ]
      );

      devPkgs = with pkgs; [
        dive
        elmPackages.elm
        elmPackages.elm-language-server
        elmPackages.elm-review
        elmPackages.elm-test
        elmPackages.elm-test-rs
        esbuild
        gnumake
        json-diff
        nixfmt
        nodejs
        playwright-test
        podman-compose
        self'.packages.elm-watch
        self'.packages.elm2nix
        sphinxEnv
        systemd-manager-tui
        watchman
      ];
    in

    {
      formatter = formatter.package;

      devShells.default =
        (devShell.extend (
          final: prev: {
            packages = prev.packages ++ devPkgs;
          }
        )).finalPackage;
    };
}
