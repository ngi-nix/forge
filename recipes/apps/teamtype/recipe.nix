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

      #### Testing locally

      To easily test Teamtype out on your local machine a demo script has been provided in this repo.
      Follow the run instructions to enter the nix shell with teamtype and run:

      ```bash
      teamtype-demo
      ```

      This will automatically open a 4-pane `tmux` session with two directories (`checkout-alice` and `checkout-bob`).
      Alice on the left will start sharing a test file.
      Copy the join code the first pane printed by Alice's share command into Bob's join command, and you can start editing the file from either side!

      *(Note: Teamtype supports more than two users! Additional people can join using the newly generated join codes printed by the host's `teamtype share` pane, or by using the same secret address.)*

      Keep in mind this demo is just a local test scenario to evaluate Teamtype quickly!
      For real-world collaboration, Teamtype works perfectly across remote machines by simply using the regular `teamtype share` and `teamtype join <code>` commands.
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
        (pkgs.writeShellScriptBin "teamtype-demo" ''
          DEMO_DIR=$(mktemp -d)
          HOST_DIR="$DEMO_DIR/checkout-alice"
          CLIENT_DIR="$DEMO_DIR/checkout-bob"
          mkdir -p "$HOST_DIR" "$CLIENT_DIR"

          # allows skipping the setup prompt
          mkdir "$HOST_DIR/.teamtype" "$CLIENT_DIR/.teamtype"
          chmod go-rwx "$HOST_DIR/.teamtype" "$CLIENT_DIR/.teamtype"

          echo "Hello shared world!" > "$HOST_DIR/demo.txt"

          # preserve PATH to an env file so tmux panes can restore it
          echo "export PATH=\"$PATH\"" > "$DEMO_DIR/.env"

          NAME="teamtype-demo-$$"

          export PATH=$PATH:${pkgs.tmux}/bin

          if [ -n "$TMUX" ]; then
            tmux new-window -n "$NAME" -c "$HOST_DIR"
            TARGET="-t $NAME"
          else
            tmux new-session -d -s "$NAME" -c "$HOST_DIR"
            TARGET="-t $NAME"
          fi

          tmux send-keys $TARGET "source \"$DEMO_DIR/.env\" && clear" C-m
          tmux send-keys $TARGET "teamtype share --username Alice" C-m

          tmux split-window $TARGET -h -c "$CLIENT_DIR"
          tmux send-keys $TARGET "source \"$DEMO_DIR/.env\" && clear" C-m
          tmux send-keys $TARGET "echo 'Paste the join code from the left pane here:'" C-m
          tmux send-keys $TARGET "teamtype join --username Bob "

          tmux select-pane $TARGET -L
          tmux split-window $TARGET -v -c "$HOST_DIR"
          tmux send-keys $TARGET "source \"$DEMO_DIR/.env\" && clear" C-m
          tmux send-keys $TARGET "nvim demo.txt" C-m

          tmux select-pane $TARGET -R
          tmux split-window $TARGET -v -c "$CLIENT_DIR"
          tmux send-keys $TARGET "source \"$DEMO_DIR/.env\" && clear" C-m
          tmux send-keys $TARGET "echo 'Once joined, run nvim here to edit!'" C-m

          if [ -z "$TMUX" ]; then
            tmux attach-session -t "$NAME"
          fi
        '')
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
