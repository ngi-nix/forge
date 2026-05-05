{
  description = "NGI Forge";

  nixConfig = {
    extra-substituters = [ "https://ngi-forge.cachix.org" ];
    extra-trusted-public-keys = [
      "ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0="
    ];
  };

  inputs = {
    # Warning(compatibility): the "ngi-forge" input name
    # is treated specially by `inputs.ngi-forge.flakeModules.default`
    # to know the ngi-forge input and sub-inputs it must use.
    ngi-forge.url = "github:ngi-nix/forge";
    flake-parts.follows = "ngi-forge/flake-parts";
    nixpkgs.follows = "ngi-forge/nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ngi-forge, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ ngi-forge.flakeModules.default ];

      debug = true;

      perSystem =
        { system, lib, ... }:
        {
          # load packages and applications from other forges
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                # WARN:
                # make sure this is unique for each provider forge you use,
                # else you may face issues
                forgePkgs = ngi-forge.packages.${system};
              })
            ];
          };

          forge = {
            repository = {
              path = "my-user/my-forge";
            };
            # Load app and package recipes using `ngi-forge.lib.loadRecipes`.
            # Note that you can wrap those into `lib.mkForce`
            # if you also want to discard ngi-forge's recipes.
            apps = inputs.ngi-forge.lib.loadRecipes {
              rootDir = inputs.self + "/recipes/apps";
              sourceUrl =
                { path }:
                "https://github.com/ngi-nix/forge/blob/${inputs.ngi-forge.lib.sourceInfoRef inputs.self}/recipe/apps/${path}";
            };
            packages = inputs.ngi-forge.lib.loadRecipes {
              rootDir = inputs.self + "/recipes/packages";
              sourceUrl =
                { path }:
                "https://github.com/ngi-nix/forge/blob/${inputs.ngi-forge.lib.sourceInfoRef inputs.self}/recipe/packages/${path}";
            };
          };
        };
    };
}
