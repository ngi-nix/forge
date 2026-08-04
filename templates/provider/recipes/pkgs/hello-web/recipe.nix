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
      vendorHash = "sha256-VTXiI77KaRZWQtbTXbWT2IHPDT9TIxklKP64Z0ip+Dc=";
      packages.run = [ pkgs.postgresql.lib ];
    };

    test.script = ''
      hello-web | grep "Hello, world!"
    '';
  };
}
