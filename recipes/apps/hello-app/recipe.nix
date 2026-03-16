{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "hello-app";
  version = "1.0.0";
  description = "Say hello in multiple languages.";

  services.default = {
    command = pkgs.mypkgs.hello;

    argv = [
      "--greeting"
      "Hello"
    ];
  };

  programs = {
    enable = true;
    requirements = [
      pkgs.mypkgs.hello
    ];
  };

  container = {
    enable = true;
    name = "hello";
    tag = "latest";
    requirements = [ pkgs.mypkgs.hello ];
    composeFile = ./compose.yaml;
  };
}
