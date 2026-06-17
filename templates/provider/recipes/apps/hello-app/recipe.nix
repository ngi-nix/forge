{
  lib,
  pkgs,
  ...
}:

{
  apps.hello-nix = {
    description = "Say hello to Nix.";
    maintainers = with lib.maintainers; [ provider-team ];

    programs = {
      packages = [
        pkgs.hello-nix
      ];

      runtimes.shell = {
        enable = true;
      };
    };
  };
}
