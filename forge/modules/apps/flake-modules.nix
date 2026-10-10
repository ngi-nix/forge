{ config, lib, ... }:
{
  flake.modules.apps =
    let
      # NixOS modules are system-agnostic, so it is sufficient to source them
      # from a single system's `forge.apps` evaluation. `config.forge.apps`
      # includes both ngi-forge's own recipes and any recipes the importing
      # flake adds itself, so this is exposed for consumer flakes too.
      apps = config.allSystems.${lib.head config.systems}.forge.apps;
      nixosApps = lib.filterAttrs (_: app: !app.broken && app.services.runtimes.nixos.enable) apps;
    in
    lib.mapAttrs (_: app: app.services.runtimes.nixos.result.nixosModule) nixosApps;
}
