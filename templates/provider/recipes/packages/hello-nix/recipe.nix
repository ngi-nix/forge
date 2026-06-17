{
  lib,
  ...
}:

{
  packages.hello-nix = {
    description = "Hello Nix package built from local source.";
    homePage = "https://github.com/ngi-nix/ngi-forge";
    mainProgram = "hello";
    license = [ lib.licenses.agpl3Only ];
    maintainers = with lib.maintainers; [ provider-team ];

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
