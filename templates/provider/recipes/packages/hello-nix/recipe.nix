{
  packages.hello-nix =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      description = "Hello Nix package built from local source";
      homePage = "https://github.com/ngi-nix/ngi-forge";
      mainProgram = "hello";
      license = [ lib.licenses.agpl3Only ];

      source = {
        path = ./../../../src;
      };

      build.standardBuilder = {
        enable = true;
      };

      build.extraAttrs = {
        makeFlags = [ "PREFIX=$(out)" ];
      };

      test.script = ''
        hello | grep "Hello Nix !"
      '';
    };
}
