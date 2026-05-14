{
  pkgs,
  ...
}:

{
  apps.hello-nix = {
    description = "Say hello to Nix.";

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
