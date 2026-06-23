{
  pkgs,
  ...
}:
{
  apps.pnut = {
    displayName = "Pnut";
    description = "C to POSIX shell transpiler for reproducible and auditable bootstrapping of GCC from a minimal seed.";
    usage = ''
      Pnut transpiles C source code to POSIX shell scripts, enabling
      reproducible and auditable bootstrapping of GCC from a minimal seed.

      #### Transpile a C file to shell

      ```bash
      pnut input.c > output.sh
      chmod +x output.sh
      ```

      #### Bootstrap pnut itself

      ```bash
      pnut pnut.c > pnut-bootstrap.sh
      chmod +x pnut-bootstrap.sh
      ```
    '';

    links = {
      website = "https://pnut.sh";
      source = "https://github.com/udem-dlteam/pnut";
    };

    ngi.grants = {
      Commons = [
        "Pnut"
        "Pnut-architectures"
      ];
    };

    programs = {
      packages = [
        pkgs.pnut
      ];

      runtimes.shell = {
        enable = true;
      };
    };
  };
}
