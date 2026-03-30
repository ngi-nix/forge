{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "hello-nix";
  description = "Hello Nix package built from local source";
  homePage = "https://github.com/imincik/nix-forge";
  mainProgram = "hello";

  source = {
    path = ./../../../src;
  };

  build.standardBuilder = {
    enable = true;
  };

  build.extraDrvAttrs = {
    makeFlags = [ "PREFIX=$(out)" ];
  };

  test.script = ''
    hello | grep "Hello Nix !"
  '';
}
