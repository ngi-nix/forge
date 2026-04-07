{
  description = "Nix Forge";

  nixConfig = {
    extra-substituters = [ "https://flake-forge.cachix.org" ];
    extra-trusted-public-keys = [
      "flake-forge.cachix.org-1:cu8to1JK8J70jntSwC0Z2Uzu6DpwgcWTS3xiiye3Lyw="
    ];
  };

  inputs = {
    nixpkgs.follows = "nix-forge/nixpkgs";
    flake-parts.follows = "nix-forge/flake-parts";
    nix-forge.url = "github:ngi-nix/forge";
    elm2nix.follows = "nix-forge/elm2nix";
    nix-utils.follows = "nix-forge/nix-utils";
    nimi.follows = "nix-forge/nimi";
  };

  outputs =
    inputs@{ flake-parts, nix-forge, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ nix-forge.flakeModules.default ];

      perSystem =
        { system, ... }:
        {
          _module.args.nimi = inputs.nimi.packages.${system}.nimi;

          forge = {
            repositoryUrl = "github:me/my-forge";
            recipeDirs = {
              packages = "recipes/packages";
              apps = "recipes/apps";
            };
          };
        };
    };
}
