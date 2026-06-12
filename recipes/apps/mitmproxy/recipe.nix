{
  pkgs,
  ...
}:

{
  apps.mitmproxy = {
    displayName = "mitmproxy";
    description = "Interactive TLS-capable intercepting HTTP proxy.";
    usage = ''
      mitmproxy is a free and open source interactive HTTPS proxy for intercepting,
      inspecting, modifying and replaying HTTP and HTTPS traffic.

      Start the interactive terminal UI

      ```bash
      mitmproxy
      ```

      Start as a plain proxy (no UI)

      ```bash
      mitmdump
      ```

      Start the web UI

      ```bash
      mitmweb
      ```
    '';

    icon = ./icon.svg;

    links = {
      website = "https://mitmproxy.org/";
      source = "https://github.com/mitmproxy/mitmproxy";
      docs = "https://docs.mitmproxy.org/stable/";
    };

    ngi.grants = {
      Entrust = [
        "mitmproxy"
      ];
    };

    programs = {
      packages = [
        pkgs.mitmproxy
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      mitmdump --version 2>&1 | grep -qi "mitmproxy"
    '';
  };
}
