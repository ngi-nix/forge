{
  config,
  pkgs,
  lib,
  ...
}:

pkgs.forgePkgs.python-web-app.extendRecipe {
  services.runtimes.nixos.extraConfig = {
    environment.systemPackages = [
      pkgs.postgresql
    ];
  };
}
