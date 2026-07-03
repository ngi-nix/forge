{
  lib,
  pkgs,
  ...
}:

{
  pkgs.hello-web = {
    version = "0.0.1";
    description = "Example web service returning hello message.";
    mainProgram = "hello-web";
    homePage = "https://github.com/ngi-nix/forge";
    license = lib.licenses.mit;

    source.path = ./src;

    build.goPackageBuilder = {
      enable = true;
      vendorHash = null;
    };

    test.script = ''
      hello-web | grep "Hello, world!"
    '';
  };
}
