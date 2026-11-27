{ forge-inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:

    let
      formatter = pkgs.callPackage ./formatter.nix { inputs = forge-inputs; };

      devShell = pkgs.callPackage ./devshell.nix {
        inputs = forge-inputs;
        inherit formatter;
      };

      # Attribute set containing packages from ./commands
      devCommands = lib.pipe devShell.commands [
        (lib.map (x: {
          name = x.package.pname or x.package.name or x.name;
          value = x.package or x.command;
        }))
        (lib.listToAttrs)
      ];

      devPython = pkgs.python3.withPackages (
        pyPkgs:
        [
          # docs
          pyPkgs.linkify-it-py
          pyPkgs.sphinx
          pyPkgs.sphinx-autobuild
          pyPkgs.myst-parser
          pyPkgs.sphinx-book-theme
          pyPkgs.sphinx-copybutton
          pyPkgs.sphinx-design
          pyPkgs.sphinx-sitemap
          pyPkgs.sphinx-notfound-page
        ]
        ++ devCommands.forge-update.passthru.dependencies
        ++ lib.concatAttrValues devCommands.forge-update.passthru.optional-dependencies
      );

      devPkgs = {
        tools = [
          pkgs.json-diff
          pkgs.nixfmt
        ];

        ui = [
          pkgs.elmPackages.elm
          pkgs.elmPackages.elm-language-server
          pkgs.elmPackages.elm-review
          pkgs.elmPackages.elm-test
          pkgs.elmPackages.elm-test-rs
          pkgs.esbuild
          pkgs.nodejs
          pkgs.watchman
          forge-inputs.self.legacyPackages.${system}.elm-watch
        ];

        ui-test = [
          pkgs.playwright-test
        ];

        dev = [
          devPython
          pkgs.dive
          pkgs.git-cliff
          pkgs.podman-compose
          pkgs.systemd-manager-tui
          forge-inputs.self.legacyPackages.${system}.elm2nix
        ];

        docs = [
          devPython
          pkgs.gnumake
        ];
      };

      allDevPkgs = lib.pipe devPkgs [
        (lib.mapAttrsToList (_: v: v))
        (lib.flatten)
      ];

      filterCommands =
        excludeNames: lib.filter (cmd: !(lib.elem (cmd.package.name or cmd.name) excludeNames));

      mkDevShell =
        {
          fromShell ? devShell,
          packages,
          excludeCommands ? [ ],
        }:

        fromShell.extend (
          final: prev: {
            packages = filterCommands excludeCommands (prev.packages ++ packages);
            defaultCmds = filterCommands excludeCommands prev.defaultCmds;
            formatters = filterCommands excludeCommands prev.formatters;
          }
        );

      devShells = {
        default = mkDevShell {
          packages = allDevPkgs;
        };

        minimal = mkDevShell {
          packages = devPkgs.tools;
          excludeCommands = [
            "forge-update"
            "test-ui"
            "treefmt"
          ];
        };

        ui = mkDevShell {
          fromShell = devShells.minimal;
          packages = devPkgs.ui;
        };

        ci = mkDevShell {
          fromShell = devShells.minimal;
          packages = with devPkgs; ui ++ ui-test;
        };
      };
    in

    {
      formatter = formatter.package;
      devShells = lib.mapAttrs (_: shell: shell.finalPackage) devShells;
      packages.forge-update = devCommands.forge-update;
    };
}
