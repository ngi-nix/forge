{
  pkgs,
  ...
}:

{
  apps.cryptolyzer = {
    displayName = "CryptoLyzer";
    description = "Cybersecurity tool that can analyse cryptographic settings of clients and servers for different protocols.";
    usage = ''
      CryptoLyzer analyses the cryptographic settings of TLS, SSH, and other
      protocol servers and clients, and tests endpoints against known vulnerabilities.

      Analyse TLS settings of a server

      ```bash
      cryptolyze tls all example.com
      ```

      Analyse SSH settings of a server

      ```bash
      cryptolyze ssh2 pubkeys example.com
      ```
    '';

    icon = ./icon.svg;

    links = {
      source = "https://gitlab.com/coroner/cryptolyzer";
      docs = "https://cryptolyzer.readthedocs.io/en/latest/";
    };

    ngi.grants = {
      Core = [
        "CryptoLyzer-IKE"
      ];
      Review = [
        "CryptoLyzer"
      ];
    };

    programs = {
      packages = [
        pkgs.cryptolyzer
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      cryptolyze --help 2>&1 | grep -qi "usage"
    '';
  };
}
