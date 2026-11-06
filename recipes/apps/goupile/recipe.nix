{
  forge-lib,
  lib,
  pkgs,
  ...
}:

{
  pkgs.goupile = {
    build.builders.identity = {
      enable = true;
      derivation =
        # TODO: Remove once https://github.com/NixOS/nixpkgs/pull/583555 is available in nixos-unstable
        if lib.hasInfix "-pFast" pkgs.pkgsOriginal.goupile.buildPhase then
          throw "PR #583555 landed for Goupile. The override in recipes/apps/goupile/recipe.nix should be removed."
        else
          (pkgs.pkgsOriginal.goupile.override {
            stdenv = pkgs.clangStdenv;
            profile = "Fast";
          }).overrideAttrs
            (old: {
              nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.llvmPackages.bintools ];
            });
    };
  };
  apps.goupile = {
    displayName = "Goupile";
    description = "Free design tool for secure forms including Clinical Report Forms (eCRF).";
    categories = with forge-lib.categories; [ Uncategorised ];
    usage = ''
      Goupile is a tool for creating secure forms, especially Clinical Report Forms (eCRF).

      It runs as a web service. It has been configured to run on [http://localhost:8181](http://localhost:8181).
    '';

    icon = ./icon.svg;

    links = {
      website = "https://goupile.org/en";
      source = "https://github.com/Koromix/rygel";
      docs = "https://goupile.org/en/setup";
    };

    ngi.grants = {
      Core = [ "Goupile" ];
    };

    services = {
      components = {
        goupile = {
          process.command = pkgs.goupile;
          process.argv = [
            "-C"
            "${./goupile.ini}"
          ];
          process.ports = [ "8181:8181" ];
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.goupile.packages = [ pkgs.goupile ];
        };

        nixos = {
          enable = true;
        };
      };
    };

    test.services = {
      script = ''
        curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

        $curl --location localhost:8181 | grep "Goupile" >/dev/null
      '';
    };
  };
}
