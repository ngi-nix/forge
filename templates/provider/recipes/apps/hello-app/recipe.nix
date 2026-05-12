{
  systemConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Say hello to Nix.";

  programs = {
    packages = [
      systemConfig.packages.hello-nix
    ];

    runtimes.shell = {
      enable = true;
    };
  };
}
