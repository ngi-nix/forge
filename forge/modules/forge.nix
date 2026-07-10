{
  config,
  lib,
  pkgs,
  self-inputs,
  forge-inputs,
  forge-lib,
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
        inherit forge-lib;
        pkgs = pkgs.extend (
          finalPkgs: previousPkgs:
          # Extend `pkgs` with the packages from the forge.
          lib.mapAttrs (packageName: package: package.result.derivation) config.forge.pkgs
          // {
            # `pkgs.pkgsOriginal` provides packages from the original `pkgs` (usually from Nixpkgs)
            # Eg. `pkgs.pkgsOriginal.offen` (Nixpkgs) and `pkgs.offen` (ngi-forge).
            # Note that as a consequence, all dependencies of those packages
            # remain those coming from the original `pkgs`,
            # even when they happen to also be packaged in the forge.
            pkgsOriginal = previousPkgs;
          }
        );
        lib = lib // {
          maintainers =
            (import "${forge-inputs.nixpkgs}/maintainers/maintainer-list.nix")
            // lib.foldl' (acc: path: acc // import path) { } config.forge.maintainerLists;
        };
      };
      modules = [
        {
          options = {
            maintainerLists = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "Paths to maintainer list files in the format of Nixpkgs maintainer-list.nix.";
              example = lib.literalExpression ''
                [ inputs.ngi-forge.maintainerList
                ./maintainers/maintainer-list.nix ]
              '';
            };

            repositoryUrl = lib.mkOption {
              type = lib.types.str;
              default = "github:ngi-nix/forge";
              example = "github:ngi-nix/forge";
              description = "URL of the flake repository.";
            };
          };
        }
      ];
    };
  };
}
