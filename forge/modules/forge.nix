{
  config,
  lib,
  pkgs,
  self-inputs,
  forge-inputs,
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
        forgeConfig = config;
        inputs = self-inputs;
        inherit forge-inputs;
        pkgs = pkgs.extend (
          finalPkgs: previousPkgs:
          # Extend `pkgs` with the `packages` from the forge.
          config.packages
          // {
            # `pkgs.pkgsOriginal` provides packages from the original `pkgs` (usually from Nixpkgs)
            # Eg. `pkgs.pkgsOriginal.offen` (Nixpkgs) and `pkgs.offen` (ngi-forge).
            # Note that as a consequence, all dependencies of those packages
            # remain those coming from the original `pkgs`,
            # even when they happen to also packaged in the forge.
            pkgsOriginal = previousPkgs;
          }
        );
        lib = lib // {
          maintainers =
            (import "${forge-inputs.nixpkgs}/maintainers/maintainer-list.nix")
            // lib.optionalAttrs (config.forge.maintainerList != null) (import config.forge.maintainerList);
        };
      };
      modules = [
        {
          options = {

            maintainerList = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Path to a maintainer list file in the format of Nixpkgs maintainer-list.nix.";
              example = "./maintainers/maintainer-list.nix";
            };

            repositoryUrl = lib.mkOption {
              type = lib.types.str;
              default = "github:ngi-nix/forge";
              example = "github:ngi-nix/forge";
              description = "URL of the flake repository.";
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
