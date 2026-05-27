{
  pkgs,
  ...
}:

{
  apps.goupile = {
    displayName = "Goupile";
    description = "Free design tool for secure forms including Clinical Report Forms (eCRF).";
    usage = ''
      Goupile is a tool for creating secure forms, especially Clinical Report Forms (eCRF).

      It runs as a web service. It has been configured to run on [http://localhost:8181](http://localhost:8181).
    '';

    icon = ./icon.svg;

    links = {
      website = "https://goupile.org/en";
      source = "https://github.com/Koromix/rygel";
      docs = "https://goupile.org/en/docs";
    };

    ngi.grants = {
      Core = [ "Goupile" ];
    };

    services = {
      components = {
        goupile = {
          command = pkgs.goupile;
          argv = [
            "-C"
            "${./goupile.ini}"
          ];
          ports = [ "8181:8181" ];
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.goupile.packages = [ pkgs.goupile ];
        };

        nixos = {
          enable = true;
        };
      };
    };

    test = {
      script = ''
        curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

        $curl --location localhost:8181 | grep -q "Goupile" >/dev/null
      '';
    };
  };
}
