{
  description = "NGI Forge provider";

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
    { self, ... }@inputs:
    inputs.ngi-forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ inputs.ngi-forge.flakeModules.base ];

      perSystem =
        { system, ... }:
        {
          forge = {
            # Configuration

            # Set Forge repository URL
            # e.g. "github:username/my-forge"
            repositoryUrl = "github:ngi-nix/forge";

            # Set maintainers
            maintainerLists = [ ./maintainers/maintainer-list.nix ];

            # Import recipe files
            imports = [ (inputs.ngi-forge.inputs.import-tree ./recipes) ];
          };
        };
    };
}
