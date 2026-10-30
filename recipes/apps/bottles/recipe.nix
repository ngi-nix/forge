{
  pkgs,
  config,
  ...
}:

{
  pkgs.bottles = {
    # TODO needs unfree packages https://github.com/ngi-nix/forge/pull/1043#issuecomment-6348128062
    unfree = true;
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.bottles;
    };
  };

  apps.bottles = {
    displayName = "Bottles";
    description = "Easy-to-use wineprefix manager.";
    usage = ''
      Bottles is an application that allows you to easily manage Windows prefixes on your favorite Linux distribution.
      A Windows prefix is an environment where it is possible to run Windows software using runners, which are compatibility layers capable of running Windows applications on a Linux system.
      These environments are called bottles.

      For information about the first run see [here](https://usebottles.com/docs/getting-started/first-run), and for more general information see [the bottles website](${config.apps.bottles.links.website}).
    '';
    # TODO needs unfree packages https://github.com/ngi-nix/forge/pull/1043#issuecomment-6348128062
    unfree = true;

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [ "Bottles" ];
    };

    links = {
      website = "https://usebottles.com/";
      docs = "https://usebottles.com/docs";
      source = "https://github.com/bottlesdevs/Bottles";
    };

    programs = {
      packages = [ pkgs.bottles ];
      runtimes.shell.enable = true;
    };

    test.programs = {
      # Checking bottles and bottles-cli are installed
      script = ''
        bottles --help | grep bottles
        bottles-cli --help | grep bottles-cli
      '';
    };
  };
}
