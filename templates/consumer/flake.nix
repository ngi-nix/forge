{
  description = "NGI Forge consumer";

  nixConfig = {
    extra-substituters = [ "https://ngi-forge.cachix.org" ];
    extra-trusted-public-keys = [
      "ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0="
    ];
  };

  inputs = {
    ngi-forge.url = "github:ngi-nix/forge";
  };

  outputs =
    inputs@{ self, ... }:
    inputs.ngi-forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ inputs.ngi-forge.flakeModules.default ];

      # Uncomment this to enable debug attributes of this flake.
      # https://flake.parts/options/flake-parts.html?highlight=debug#opt-debug
      # debug = true;

      perSystem =
        { config, pkgs, ... }:
        {
          # nix fmt
          formatter = pkgs.nixfmt-tree;

          forge = {
            # NOTE: update the repository url to your forge. e.g. "github:username/forge-repo"
            repositoryUrl = "github:ngi-nix/forge";
            imports = [ (inputs.ngi-forge.inputs.import-tree ./recipes) ];
          };
        };

      # NixOS system configuration
      flake.nixosConfigurations.offen = inputs.ngi-forge.inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Boot configuration.
          # Low priorities let the image variants of `system.build.images` replace these values.
          (
            { lib, ... }:
            {
              fileSystems."/" = lib.mkDefault {
                device = "/dev/disk/by-label/nixos";
                fsType = "ext4";
              };
              # Priority 1100 is between `lib.mkDefault` (1000) and the option default (1500).
              boot.loader.grub.device = lib.mkOverride 1100 "/dev/sda";
            }
          )
          # Application module. See: recipes/apps/offen/recipe.nix
          self.packages.x86_64-linux.apps.offen.nixosModules.default
        ];
      };
    };
}
