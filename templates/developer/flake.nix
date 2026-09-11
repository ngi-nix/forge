{
  description = "NGI Forge developer";

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

      # Uncomment this to enable debug attributes of this flake.
      # https://flake.parts/options/flake-parts.html?highlight=debug#opt-debug
      # debug = true;

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          # nix fmt
          formatter = pkgs.nixfmt-tree;

          devShells.default = pkgs.mkShell {
            # Install build dependencies of a Forge package.
            # NOTE: this doesn't include package itself
            inputsFrom = [
              config.packages.pkgs.offen
            ];

            # Install additional packages
            packages = [
              # pkgs.jq
            ];
          };
        };
    };
}
