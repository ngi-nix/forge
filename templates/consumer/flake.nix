{
  description = "NGI Forge";

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
    inputs:
    inputs.ngi-forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } (flakeArgs: {
      systems = [ "x86_64-linux" ];
      imports = [ inputs.ngi-forge.flakeModules.default ];

      # To access the toplevel `config` while debugging in `nix repl .`
      flake.flakeConfig = flakeArgs.config;

      perSystem =
        {
          system,
          pkgs,
          lib,
          ...
        }:
        {
          forge = {
            imports = [ (inputs.ngi-forge.inputs.import-tree ./recipes) ];
            repositories.${lib.unsafeDiscardStringContext inputs.self} = repo: {
              homeUrl = "https://github.com/" + repo.config.path;
              path = "my-user/my-repository";
            };
          };
        };
    });
}
