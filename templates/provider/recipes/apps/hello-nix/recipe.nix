{
  lib,
  pkgs,
  ...
}:

{
  apps.hello-nix = {
    displayName = "Program Example";
    description = "Simple program configuration.";
    maintainers = with lib.maintainers; [ provider-team ];
    categories = with lib.categories; [ Development ];

    programs = {
      packages = [ pkgs.hello-nix ];
      mainPackage = pkgs.hello-nix;

      runtimes = {
        program.enable = true;
        shell.enable = true;
      };
    };

    test.programs = {
      script = ''
        hello | grep "Hello Nix !"
      '';
    };
  };
}
