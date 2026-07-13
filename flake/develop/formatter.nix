{
  lib,
  pkgs,
  inputs,
  ...
}:
lib.makeExtensible (self: {
  treefmt = import inputs.treefmt-nix;

  config = {
    projectRootFile = "flake.nix";

    programs.actionlint.enable = true;
    programs.black.enable = true;
    programs.gofmt.enable = true;
    programs.elm-format.enable = true;
    programs.nixfmt.enable = true;
    programs.shellcheck.enable = true;
    programs.shfmt.enable = true;

    programs.dprint = {
      enable = true;
      includes = [
        "**/*.{json,jsonc,md,js,ts,yml,yaml}"
        "*.{json,jsonc,md,js,ts,yml,yaml}"
      ];
      excludes = [
        "**/node_modules"
        "**/*-lock.json"
      ];
      settings = {
        plugins = pkgs.dprint-plugins.getPluginList (
          ps: with ps; [
            dprint-plugin-json
            dprint-plugin-markdown
            dprint-plugin-typescript
            g-plane-pretty_yaml
          ]
        );
      };
    };

    settings.formatter.editorconfig-checker = {
      command = pkgs.editorconfig-checker;
      includes = [ "*" ];
      priority = 9; # last
    };
  };

  # useful for debugging
  eval = self.treefmt.evalModule pkgs self.config;

  # treefmt package
  package = self.eval.config.build.wrapper;

  # development shell (contains all formatters)
  shell = self.eval.config.build.devShell;
})
