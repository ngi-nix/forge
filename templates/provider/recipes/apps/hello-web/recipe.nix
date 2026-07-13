{ pkgs, ... }:

{
  apps.hello-web = {
    displayName = "Service Example";
    description = "Simple service configuration.";
    usage = ''
      This application demonstrates the _hello-web_ package running as a
      simple standalone service.

      Run _hello-web_ as a web service in a _container_ or _nixos_ runtime.

      The web service returns a default greeting:

      ```bash
      curl localhost:5000/
      ```

      ```bash
      Hello, world!
      ```
    '';

    links = {
      website = "https://github.com/ngi-nix/forge";
    };

    ngi.grants = {
      Commons = [
        "Example 1"
        "Example 2"
      ];
      Core = [
        "Example 1"
        "Example 2"
      ];
    };

    services = {
      components.web = {
        process = {
          command = pkgs.hello-web;
          argv = [ "serve" ];
          packages = [ pkgs.hello-web ];
          ports = [ "5000:5000" ];
        };
      };

      runtimes = {
        container.enable = true;
        nixos.enable = true;
      };
    };

    test.services = {
      script = ''
        curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"
        $curl localhost:5000/ | grep "Hello, world!"
      '';
    };
  };
}
