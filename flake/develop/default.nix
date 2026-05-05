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
        gnumake
        sphinxEnv
        elmPackages.elm
        elmPackages.elm-language-server
        elmPackages.elm-review
        elmPackages.elm-test
        elmPackages.elm-test-rs
        esbuild
        json-diff
        nixfmt
        nodejs
        self'.packages.elm-watch
        self'.packages.elm2nix
        playwright-test
        systemd-manager-tui
        watchman
        podman-compose
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
