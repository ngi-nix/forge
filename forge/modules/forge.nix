{
  config,
  lib,
  pkgs,
  system,
  self-inputs,
  forge-inputs,
  ngi-forge-lib,
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
        inherit forge-inputs;
        inherit ngi-forge-lib;
        inherit self-inputs;
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
      };
      modules = [ ];
    };
  };
}
