{
  systemConfig,
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
      systemConfig.packages.hello-nix
    ];

    runtimes.shell = {
      enable = true;
    };
  };
}
