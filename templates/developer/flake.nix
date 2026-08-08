{
  description = "NGI Forge-based Development flake";

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
        {
          config,
          pkgs,
          ...
        }:
        {
          devShells.default = pkgs.mkShell {
            # Install build dependencies required to build the apps/pkgs
            # NOTE:
            #   This does not include the tools themselves.
            #   For that, use `packages`, below.
            inputsFrom = [
              config.packages.apps.cpdf
              config.packages.apps.qlever
              config.packages.pkgs.arwen
            ];

            # Install build tools
            packages = [
              config.packages.pkgs.arwen
              pkgs.coreutils
              pkgs.jq
            ]
            # include forge packages (main executables)
            ++ config.packages.apps.cpdf.pkgs
            ++ config.packages.apps.qlever.pkgs;
          };
        };
    };
}
