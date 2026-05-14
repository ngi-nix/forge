{
  apps.hello-nix =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
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
