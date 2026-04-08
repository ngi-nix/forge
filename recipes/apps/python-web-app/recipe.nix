{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "python-web-app";
  description = "Example web API with database backend.";
  usage = ''
    This is a simple example application that provides a web API for
    managing a list of users.

    * Initialize database
    ```
    curl -X POST localhost:5000/init
    ```

    * Add a new user
    ```
    curl -X POST \
      --header "Content-Type: application/json" \
      --data '{"name":"username"}' \
    localhost:5000/users
    ```

    * Get list of all users
    ```
    curl localhost:5000/users
    ```
  '';

  links = {
    website = pkgs.mypkgs.python-web.meta.homepage;
    docs = pkgs.mypkgs.python-web.meta.homepage;
    source = pkgs.mypkgs.python-web.meta.homepage;
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
    enable = true;
    requirements = [
      pkgs.curl
    ];
  };

  services = {
    components = {
      python-web = {
        command = pkgs.mypkgs.python-web;
      };
    };

    runtimes = {
      container = {
        enable = true;
        requirements = [ pkgs.mypkgs.python-web ];
        # Alternatively, we can re-use attributes with `config`:
        #requirements = [ config.services.python-web.command ];
        composeFile = ./compose.yaml;
      };

      nixos = {
        enable = true;
        extraConfig = {
          # database service
          services.postgresql.enable = true;
          services.postgresql.enableTCPIP = true;
          services.postgresql.authentication = ''
            local all all trust
            host all all 0.0.0.0/0 trust
            host all all ::0/0 trust
          '';
        };
        vm.forwardPorts = [
          "5000:5000"
        ];
      };
    };
  };

  test.script = ''
    curl -X POST localhost:5000/init

    curl -X POST \
      --header "Content-Type: application/json" \
      --data '{"name":"username"}' \
      localhost:5000/users

    curl localhost:5000/users
  '';
}
