{
  pkgs,
  ...
}:

{
  apps.example = {
    displayName = "Example App";
    description = "Example application demonstrating multiple Forge runtimes.";
    usage = ''
      This application demonstrates the _hello-web_ package running across all
      Forge runtimes.

      Follow the run instructions to

      - Run CLI in a _program_ or in a_shell_ runtime

      ```bash
      $ hello-web

      Hello, world!
      ```

      - Or, run service at [http://localhost:5000](http://localhost:5000) in
        a _container_ or in a _nixos_ runtime
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

    programs = {
      packages = [ pkgs.hello-web ];
      mainPackage = pkgs.hello-web;
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    services = {
      components.hello-web = {
        command = pkgs.hello-web;
        argv = [ "serve" ];
        ports = [ "5000:5000" ];
      };

      runtimes = {
        container = {
          enable = true;
        };

        nixos = {
          enable = true;
        };
      };
    };

    test.services = {
      script = ''
        curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"
        $curl localhost:5000 | grep "Hello, world!"
      '';
    };
  };
}
