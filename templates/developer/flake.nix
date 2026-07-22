{
  description = "NGI Forge";

  nixConfig = {
    extra-substituters = [
      "https://ngi-forge.cachix.org"
    ];
    extra-trusted-public-keys = [
      "ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0="
    ];
  };

  inputs = {
    ngi-forge.url = "github:ngi-nix/forge";
  };

  outputs =
    { self, ngi-forge, ... }@inputs:
    ngi-forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ ngi-forge.flakeModules.default ];

      perSystem =
        { system, pkgs, ... }:
        {
          devShells.default = pkgs.mkShell {
            # Install build dependencies required to build the apps/pkgs
            # NOTE:
            #   This does not include the tools themselves.
            #   For that, use `packages`, below.
            inputsFrom = [
              ngi-forge.packages.${system}.apps.cpdf
              ngi-forge.packages.${system}.apps.qlever
              # TODO: https://github.com/ngi-nix/forge/issues/772
              ngi-forge.inputs.nixpkgs.legacyPackages.${system}.arwen
            ];

            # Install build tools
            packages = [
              ngi-forge.inputs.nixpkgs.legacyPackages.${system}.arwen
              pkgs.coreutils
              pkgs.jq
            ]
            # include forge packages (main executables)
            ++ ngi-forge.packages.${system}.apps.cpdf.pkgs
            ++ ngi-forge.packages.${system}.apps.qlever.pkgs;
          };
        };
    };
}
