{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "hello-app";
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
