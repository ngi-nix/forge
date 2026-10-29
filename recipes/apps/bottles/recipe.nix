{
  config,
  ...
}:

{
  apps.bottles = {
    displayName = "Bottles";
    description = "Easy-to-use wineprefix manager.";
    usage = ''
      Bottles is an application that allows you to easily manage Windows prefixes on your favorite Linux distribution.
      A Windows prefix is an environment where it is possible to run Windows software using runners, which are compatibility layers capable of running Windows applications on a Linux system.
      These environments are called bottles.

      For information about the first run see [here](https://usebottles.com/docs/getting-started/first-run), and for more general information see [the bottles website](${config.apps.bottles.links.website}).
    '';

    # Pinned to the last working Nixpkgs revision before lsfg-vk unfree dependency regression
    nixpkgsPin = {
      rev = "c59305bab2065cfecc4944690d9eedbb56f3a9fa";
      narHash = "sha256-69xHQhAeMAD2wDXO7T2pcOZIF9Sga2W+JkmY2a11Ops=";
    };

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
      packages = pkgs: [ pkgs.bottles ];
      mainPackage = pkgs: pkgs.bottles;
      runtimes.program.enable = true;
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
