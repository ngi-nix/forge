{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:

    let
      formatter = pkgs.callPackage ./formatter.nix { inherit inputs; };
      devShell = pkgs.callPackage ./devshell.nix { inherit inputs formatter; };

      sphinxEnv = pkgs.python3.withPackages (pyPkgs: [
        pyPkgs.linkify-it-py
        pyPkgs.sphinx
        pyPkgs.myst-parser
        pyPkgs.sphinx-book-theme
        pyPkgs.sphinx-copybutton
        pyPkgs.sphinx-design
        pyPkgs.sphinx-sitemap
        pyPkgs.sphinx-notfound-page
      ]);

      devPkgs = [
        pkgs.dive
        pkgs.elmPackages.elm
        pkgs.elmPackages.elm-language-server
        pkgs.elmPackages.elm-review
        pkgs.elmPackages.elm-test
        pkgs.elmPackages.elm-test-rs
        pkgs.esbuild
        pkgs.gnumake
        pkgs.json-diff
        pkgs.nixfmt
        pkgs.nodejs
        pkgs.playwright-test
        pkgs.podman-compose
        pkgs.systemd-manager-tui
        pkgs.watchman
        inputs.ngi-forge.packages.${system}.elm-watch
        inputs.ngi-forge.packages.${system}.elm2nix
        sphinxEnv
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
