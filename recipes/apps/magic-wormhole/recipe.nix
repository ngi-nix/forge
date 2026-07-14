{
  pkgs,
  ...
}:

{
  apps.magic-wormhole = {
    displayName = "Magic Wormhole";
    description = "Securely transfer files between computers.";
    usage = ''
      Get things from one computer to another, safely.

      Run the command to send or receive a file:

      ```bash
      wormhole send file.txt
      # on the other end
      wormhole receive <code-phrase>
      ```

      #### Testing locally

      To easily test Magic Wormhole out on your local machine a demo script has been provided in this repo.
      Follow the run instructions to enter the nix shell with magic-wormhole and run:

      ```bash
      magic-wormhole-demo
      ```

      This will automatically open a 2-pane `tmux` session with two directories (`alice` and `bob`).
      Alice on the left will start sending a test file.
      Copy the wormhole code the first pane printed by Alice's send command into Bob's receive command, and you can see the file transferred!
    '';

    links = {
      docs = "https://magic-wormhole.readthedocs.io";
      source = "https://github.com/magic-wormhole/magic-wormhole";
    };

    ngi.grants = {
      Core = [
        "SPAKE2"
      ];
    };

    programs = {
      packages = [
        pkgs.magic-wormhole
        (pkgs.writeShellScriptBin "magic-wormhole-demo" ''
          DEMO_DIR=$(mktemp -d)
          HOST_DIR="$DEMO_DIR/alice"
          CLIENT_DIR="$DEMO_DIR/bob"
          mkdir -p "$HOST_DIR" "$CLIENT_DIR"

          echo "Hello from Alice!" > "$HOST_DIR/secret.txt"

          # preserve PATH to an env file so tmux panes can restore it
          echo "export PATH=\"$PATH\"" > "$DEMO_DIR/.env"

          NAME="wormhole-demo-$$"

          export PATH=$PATH:${pkgs.tmux}/bin

          if [ -n "$TMUX" ]; then
            tmux new-window -n "$NAME" -c "$HOST_DIR"
            TARGET="-t $NAME"
          else
            tmux new-session -d -s "$NAME" -c "$HOST_DIR"
            TARGET="-t $NAME"
          fi

          tmux send-keys $TARGET "source \"$DEMO_DIR/.env\" && clear" C-m
          tmux send-keys $TARGET "wormhole send secret.txt" C-m

          tmux split-window $TARGET -h -c "$CLIENT_DIR"
          tmux send-keys $TARGET "source \"$DEMO_DIR/.env\" && clear" C-m
          tmux send-keys $TARGET "echo 'Paste the wormhole code from the left pane here:'" C-m
          tmux send-keys $TARGET "wormhole receive "

          if [ -z "$TMUX" ]; then
            tmux attach-session -t "$NAME"
          fi
        '')
      ];
      mainPackage = pkgs.magic-wormhole;

      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    services = {
      components.mailbox = {
        process.command = "${
          pkgs.python3.withPackages (ps: [ ps.magic-wormhole-mailbox-server ])
        }/bin/twistd";
        process.argv = [
          "-n"
          "wormhole-mailbox"
        ];
        process.ports = [ "4000:4000" ];
      };

      components.transit = {
        process.command = "${
          pkgs.python3.withPackages (ps: [ ps.magic-wormhole-transit-relay ])
        }/bin/twistd";
        process.argv = [
          "-n"
          "transitrelay"
        ];
        process.ports = [ "4001:4001" ];
      };

      runtimes.container.enable = true;
      runtimes.nixos.enable = true;
    };

    test.programs.script = ''
      wormhole --version | grep -q ${pkgs.magic-wormhole.version}
    '';

    test.services.script = ''
      curl -s -f --retry 10 --retry-max-time 120 --retry-all-errors http://localhost:4000/ | grep -q "Wormhole Relay"

      timeout 120 bash -c 'until echo > /dev/tcp/localhost/4001 2>/dev/null; do sleep 1; done'
    '';
  };
}
