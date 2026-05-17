{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ironcalc-app";
  displayName = "IronCalc";
  description = "Open source selfhosted spreadsheet engine.";

  usage = ''
    IronCalc is an Open source spreadsheet engine and ecosystem.

    #### Access

    Ironcalc will be available on [http://localhost:8000](http://localhost:8000).

    You can specify a different port via `ROCKET_PORT`, and different database path with `IRONCALC_DB_PATH` environment variables.

  '';

  icon = ./icon.svg;

  links = {
    website = "https://www.ironcalc.com";
    docs = "https://docs.ironcalc.com/";
    source = "https://github.com/ironcalc/IronCalc";
  };

  ngi.grants = {
    Core = [ "IronCalc" ];
    Commons = [
      "IronCalc-conditional"
      "IronCalc-NC"
    ];
  };

  services = {
    components.ironcalc = {
      command = "${pkgs.mypkgs.ironcalc}/bin/ironcalc";
      environment = {
        ROCKET_ADDRESS = "0.0.0.0";
        IRONCALC_DB_PATH = "/var/lib/ironcalc/ironcalc.sqlite";
      };
    };

    runtimes.container = {
      enable = true;
      composeFile = ./compose.yaml;
      components.ironcalc.packages = [ pkgs.mypkgs.ironcalc ];
    };

    runtimes.nixos = {
      enable = true;
      packages = [ pkgs.mypkgs.ironcalc ];
    };

    ports = [ "8000:8000" ];
  };

  test.packages = [ pkgs.curl ];
  test.script = ''
    curl="curl --retry 8 --retry-max-time 120 --retry-all-errors"
    $curl localhost:8000 | grep -q "IronCalc"
  '';
}
