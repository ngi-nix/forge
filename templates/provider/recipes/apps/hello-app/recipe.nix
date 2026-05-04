{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  description = "Say hello to Nix.";

  programs = {
    packages = [
      rootConfig.packages.hello-nix
    ];

    runtimes.shell = {
      enable = true;
    };
  };
}
