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
      # `flakeModules.offen` restricts `forge.apps` to just `offen`, instead
      # of every app recipe ngi-forge ships, so only `offen` gets evaluated.
      # Use `flakeModules.default` to also get ngi-forge's own recipes.
      #
      # `forge.pkgs` (custom packages app recipes may depend on, eg.
      # `pkgs.offen`) is not scoped automatically, since there's no static
      # link between an app and the packages it uses. Narrow it down
      # yourself if you also want `nix flake show` to skip unrelated
      # packages; the app recipe's own source shows which ones it needs.
      imports = [
        inputs.ngi-forge.flakeModules.offen
        {
          perSystem =
            { lib, ... }:
            {
              options.forge.pkgs = lib.mkOption {
                apply = lib.filterAttrs (name: _: builtins.match "offen.*" name != null);
              };
            };
        }
      ];

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
          # Boot configuration
          {
            fileSystems."/" = {
              device = "/dev/disk/by-label/nixos";
              fsType = "ext4";
            };
            boot.loader.grub.devices = [ "/dev/sda" ];
          }
          # Application module. See: recipes/apps/offen/recipe.nix
          self.modules.apps.offen
        ];
      };
    };
}
