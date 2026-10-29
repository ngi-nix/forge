{
  pkgs,
  ...
}:

{
  pkgs.goupile = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.goupile;
    };
  };
  apps.goupile = {
    displayName = "Goupile";
    description = "Free design tool for secure forms including Clinical Report Forms (eCRF).";
    screenshotSources.urls = [
      {
        url = "https://codeberg.org/Koromix/rygel/raw/branch/master/web/goupile.org/en/static/screenshots/editor.webp";
        caption = "Create and test forms with the form editor";
      }
      {
        url = "https://codeberg.org/Koromix/rygel/raw/branch/master/web/goupile.org/en/static/screenshots/data.webp";
        caption = "Enter and export data from the same screen";
      }
      {
        url = "https://codeberg.org/Koromix/rygel/raw/branch/master/web/goupile.org/en/static/screenshots/overview.webp";
        caption = "Share forms with colleagues and users to collect data";
      }
      {
        url = "https://codeberg.org/Koromix/rygel/raw/branch/master/web/goupile.org/en/static/screenshots/tablet.webp";
        caption = "Data entry on a tablet";
      }
      {
        url = "https://codeberg.org/Koromix/rygel/raw/branch/master/web/goupile.org/en/static/screenshots/admin.webp";
        caption = "Administration module for projects and users";
      }
    ];
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
          process.command = pkgs.goupile;
          process.argv = [
            "-C"
            "${./goupile.ini}"
          ];
          process.ports = [ "8181:8181" ];
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

    test.services = {
      script = ''
        curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

        $curl --location localhost:8181 | grep "Goupile" >/dev/null
      '';
    };
  };
}
