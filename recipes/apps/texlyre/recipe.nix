{
  pkgs,
  ...
}:
{
  apps.texlyre = {
    displayName = "Texlyre";
    description = "Local-first real-time LaTeX and Typst collaboration platform with offline editing capabilities.";
    usage = ''
      TeXlyre is a local-first, real-time LaTeX and Typst collaboration platform.
      Documents are stored locally in the browser (IndexedDB) and synchronized
      with collaborators peer-to-peer over WebRTC, so editing keeps working
      offline.

      Web interface: [http://localhost:3000](http://localhost:3000)
    '';

    links = {
      website = "https://texlyre.github.io";
      source = "https://github.com/texlyre/texlyre";
      docs = "https://texlyre.github.io/docs/intro";
    };

    ngi.grants = {
      Commons = [
        "Texlyre"
      ];
    };

    icon = ./icon.svg;

    services = {
      components.texlyre = {
        process = {
          command = pkgs.texlyre;
          ports = [ "3000:3000" ];
        };
      };
      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test.services.script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"
      $curl localhost:3000 | grep "TeXlyre"
    '';
  };
}
