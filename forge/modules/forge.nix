{
  config,
  lib,
  pkgs,
  flakeInputs,
  system,
  ...
}:
{
  options.forge = lib.mkOption {
    description = "Module-system framework for building packages and apps (eg. NixOS VMs, or Podman containers) using those packages.";
    default = { };
    type = lib.types.submoduleWith {
      specialArgs = {
        inherit system;
        inputs = flakeInputs;
        # Extend `pkgs` with the per-system `packages`.
        pkgs = pkgs.extend (final: prev: config.packages);
        # In rare cases (eg. when used in the `default` of an option),
        # the non-extended `pkgs` must be used to avoid an `infinite recursion`,
        # it is provided as `nixpkgs-pkgs`.
        nixpkgs-pkgs = pkgs;
      };
      modules = [
        {
          options = {

            repositoryUrl = lib.mkOption {
              type = lib.types.str;
              default = "github:ngi-nix/forge";
              description = ''
                NGI Forge repository URL.
              '';
              example = "github:ngi-nix/forge";
            };

            recipeDirs = {
              packages = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "recipes/packages";
                description = ''
                  Directory containing package recipe files.
                  Each recipe should be a recipe.nix file in a subdirectory
                  (e.g., recipes/packages/hello/recipe.nix).

                  Set to null to disable automatic package recipe loading.
                '';
                example = "recipes/packages";
              };

              apps = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "recipes/apps";
                description = ''
                  Directory containing app recipe files.
                  Each recipe should be a recipe.nix file in a subdirectory
                  (e.g., recipes/apps/my-app/recipe.nix).

                  Set to null to disable automatic app recipe loading.
                '';
                example = "recipes/apps";
              };
            };

          };
        }
      ];
    };
  };
}
