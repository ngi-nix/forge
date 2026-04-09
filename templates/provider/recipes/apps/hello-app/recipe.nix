{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "hello-app";
  description = "Say hello to Nix.";

  programs = {
    components.default = {
      requirements = [
        pkgs.mypkgs.hello-nix
      ];
    };

    runtimes.shell = {
      enable = true;
    };
  };

  services = {
    runtimes = {
      container = {
        enable = true;
        requirements = [ pkgs.mypkgs.hello-nix ];
        imageConfig.CMD = [
          "hello"
        ];
        composeFile = ./compose.yaml;
      };

      nixos = {
        enable = true;
        extraConfig = {
          environment.systemPackages = [
            pkgs.mypkgs.hello-nix
          ];
        };
      };
    };
  };
}
