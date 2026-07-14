{
  pkgs,
  ...
}:

{
  apps.winden = {
    displayName = "Winden";
    description = "Securely transfer files between computers via the browser.";
    usage = ''
      Winden is a web interface for Magic Wormhole.
    '';

    links = {
      website = "https://winden.app";
      source = "https://github.com/LeastAuthority/winden";
    };

    ngi.grants = {
      Core = [
        "Winden-MWH-Dilation"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [ pkgs.winden ];
    };

    services = {
      components.web = {
        process.command = "${pkgs.python3}/bin/python3";
        process.argv = [
          "-m"
          "http.server"
          "8080"
          "--directory"
          "${pkgs.winden}/share/winden"
        ];
        process.ports = [ "8080:8080" ];
      };

      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test.services.script = ''
      curl --retry 5 --retry-max-time 120 --retry-all-errors http://localhost:8080 | grep -q "Winden"
    '';
  };
}
