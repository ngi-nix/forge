{
  pkgs,
  ...
}:

{
  apps.teamtype = {
    displayName = "Teamtype";
    description = "Real-time co-editing of local text files.";
    usage = ''
      Teamtype (previously Ethersync) enables real-time collaborative editing of local text files.

      Run the teamtype command to share or join a session:

      ```bash
      teamtype share
      # or
      teamtype join <code>
      ```

      > [!NOTE]
      > Teamtype relies on public [Magic Wormhole](https://github.com/magic-wormhole/magic-wormhole) relays to generate join codes. If you see a warning like "Failed to register a new join code via Magic Wormhole", the public relay might be down. You can verify this by checking if `curl http://relay.magic-wormhole.io:4000/v1` connects successfully.
      >
      > If the relay is down, you can bypass the join code by sharing a secret address directly:
      > ```bash
      > teamtype share --no-join-code --show-secret-address
      > ```
      > Peers can then add the printed `peer="<secret>"` line to their `.teamtype/config` and run `teamtype join`.

      > [!NOTE]
      > Even if join codes generate successfully, peers may still fail to connect if your network blocks IPv6 (preventing [Iroh](https://iroh.computer/)'s P2P relay discovery). If a new join code generates immediately after a peer attempts to join, try disabling IPv6 on both machines:
      > ```bash
      > sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
      > sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
      > ```


      This environment also provides Neovim and VSCodium with the Teamtype plugin pre-configured.
      Simply launch your preferred editor to start collaborating:

      ```bash
      nvim
      # or
      codium
      ```
    '';

    icon = ./icon.svg;

    links = {
      website = "https://teamtype.github.io";
      source = "https://github.com/teamtype/teamtype";
      docs = "https://teamtype.github.io/teamtype/editor-plugin-dev-guide.html";
    };

    ngi.grants = {
      Core = [
        "Teamtype"
      ];
    };

    programs = {
      packages = [
        pkgs.teamtype
        (pkgs.neovim.override {
          configure = {
            packages.myPlugins = {
              start = [ pkgs.vimPlugins.teamtype ];
            };
          };
        })
        (pkgs.vscode-with-extensions.override {
          vscode = pkgs.vscodium;
          vscodeExtensions = [ pkgs.vscode-extensions.teamtype.teamtype ];
        })
      ];
      mainPackage = pkgs.teamtype;

      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      teamtype -V | grep -q ${pkgs.teamtype.version}
    '';
  };
}
