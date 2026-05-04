{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  displayName = "Python Web Example";
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

    _Available in: container, nixos._
  '';

  links = {
    website = rootConfig.packages.python-web.meta.homepage;
    docs = rootConfig.packages.python-web.meta.homepage;
    source = rootConfig.packages.python-web.meta.homepage;
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
    components = {
      python-web = {
        command = rootConfig.packages.python-web;
      };
    };

    runtimes = {
      container = {
        enable = true;
        packages = [ rootConfig.packages.python-web ];
        # Alternatively, we can re-use attributes with `config`:
        #packages = [ config.services.python-web.command ];
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

  test = {
    script = ''
      curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

      $curl -X POST localhost:5000/init

      $curl -X POST \
        --header "Content-Type: application/json" \
        --data '{"name":"username"}' \
        localhost:5000/users

      $curl localhost:5000/users
    '';
    # test-container requires database image from Internet registry
    sandbox = false;
  };
}
