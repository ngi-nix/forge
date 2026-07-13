{
  pkgs,
  ...
}:

{
  apps.ip2unix = {
    displayName = "ip2unix";
    description = "Turn IP sockets into Unix domain sockets.";
    usage = ''
      A lot of programs are designed to only work with IP sockets, however very few of them allow to communicate via Unix domain sockets. Unix domain sockets usually are just files, so standard Unix file permissions apply to them.

      IP sockets also have the disadvantage that other programs on the same host are able to connect to them, unless you use complicated netfilter rules or network namespaces.

      So if you either have a multi-user system or just want to separate privileges, Unix domain sockets are a good way to achieve that.

      Another very common use case in nowadays systems is when you’re using systemd and want to use socket units for services that don’t support socket activation. Apart from getting rid of the necessity to specify explicit dependencies, this is also very useful for privilege separation, since a lot of services can be run in a separate network namespace.

      The systemd use case is also useful even when not using Unix domain sockets in socket units, since it allows to add IP-based socket activation to services that don’t support it.

      ##### Short example

      Let's say you have a small HTTP server you want to make available behind a HTTP reverse proxy.

      ```bash
      $ ip2unix -r path=/run/my-http-server.socket my-http-server
      ```

      This will simply convert all IP sockets to the Unix domain socket available at ``/run/my-http-server.socket`. If you use a web server like nginx, you can use the following directive to connect to that socket:

      ```
      proxy_pass http://unix:/run/my-http-server.socket;
      ```

      For more usage information.

      ```bash
      ip2unix --help
      # or
      man ip2unix
      ```

      See also
        - [More examples](https://github.com/nixcloud/ip2unix#examples)
        - [Limitations](https://github.com/nixcloud/ip2unix#limitations)
        - [FAQ](https://github.com/nixcloud/ip2unix#6-frequently-asked-questions)
    '';

    links = {
      source = "https://github.com/nixcloud/ip2unix";
      docs = "https://github.com/nixcloud/ip2unix#2-rule-specification";
    };

    ngi.grants = {
      Review = [
        "nixcloud-webservices"
        "webservicesecurity"
      ];
    };

    programs = {
      packages = [
        (
          # https://github.com/NixOS/nixpkgs/pull/541395
          pkgs.ip2unix.override {
            python3Packages = pkgs.python313Packages;
          }
        )
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      ip2unix --version 2>&1 | grep -qi "ip2unix"
    '';
  };
}
