{
  description = "NGI Forge";

  nixConfig = {
    extra-substituters = [ "https://ngi-forge.cachix.org" ];
    extra-trusted-public-keys = [
      "ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elm2nix = {
      url = "github:dwayne/elm2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-utils = {
      url = "github:imincik/nix-utils";
      flake = false;
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nimi = {
      url = "github:ngi-nix/nimi/ngi-patches";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:

    flake-parts.lib.mkFlake
      {
        inputs = inputs // {
          ngi-forge = self;
        };
      }
      (flakeArgs: {
        # Uncomment this to enable flake-parts debug.
        # https://flake.parts/options/flake-parts.html?highlight=debug#opt-debug
        # debug = true;

        systems = [
          "x86_64-linux"
          # "aarch64-linux"
          # "aarch64-darwin"
          # "x86_64-darwin"
        ];

        imports = [
          ./forge/modules.nix
          ./forge/packages.nix # Generates _forge-config, _forge-options, _forge-ui
          ./flake/develop
          ./flake/packages.nix
          ./flake/checks.nix
          ./flake/templates.nix
        ];

        # Export the flake configuration to ease exploration in `nix repl .`.
        #
        # Remark(clarity): like all `unknown` flake outputs,
        # this currently raise a warning in `nix flake check`:
        # > warning: unknown flake output 'flakeConfig'
        # Issue: https://github.com/NixOS/nix/issues/6381
        flake.flakeConfig = flakeArgs.config;

        perSystem =
          { system, ... }:
          {
            forge = {
              repositoryUrl = "github:ngi-nix/forge";
              recipeDirs = {
                packages = "recipes/packages";
                apps = "recipes/apps";
              };
            };
          };
      });
}
