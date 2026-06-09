{
  pkgs,
  ...
}:
{
  apps.sockstrace = {
    displayName = "SocksTrace";
    description = "Ptrace-based proxy leak detector that identifies network connections bypassing configured proxies.";
    usage = ''
      SocksTrace uses Linux ptrace to intercept socket syscalls and detect network
      connections that bypass configured proxies such as Tor.

      #### Example

      Trace a command and detect any proxy leaks

      ```bash
      sockstrace -horklump.program curl -horklump.args https://example.com
      ```
    '';

    links = {
      source = "https://github.com/namecoin/sockstrace";
    };

    ngi.grants = {
      Core = [
        "SocksTrace"
      ];
    };

    programs = {
      packages = [
        pkgs.sockstrace
      ];

      runtimes.shell = {
        enable = true;
      };
    };
  };
}
