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
          # Warning(compatibility): `self` being relative to the `flake.nix`,
          # `ngi-forge` is reserved as a special input name to refer to this very `flake.nix`,
          # it is here set to `self`, and users making their own forge
          # must set it to the ngi-forge input they want to use.
          ngi-forge = self;
        };
      }
      {
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
          ./flake/develop
          ./flake/packages.nix
          ./flake/checks.nix
          ./flake/templates.nix
          ./forge/flake-module.nix
        ];
      };
}
