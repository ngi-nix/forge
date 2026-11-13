{
  forge-lib,
  config,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.neuropil;
  usageSnippets = forge-lib.snippets.usage app;
in

{
  pkgs.neuropil = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.callPackage ../../_nixpkgs/neuropil { };
    };
  };

  apps.neuropil = {
    displayName = "Neuropil";
    description = "Secure & distributed M2M cybersecurity mesh.";
    longDescription = ''
      Neuropil is a small C library which by default adds two layers of
      encryption to communication channels.

      It allows you to address identities (devices, applications, services or
      people) worldwide without compromising privacy or security
      requirements.
    '';

    categories = with forge-lib.categories; [
      Security
    ];

    # TODO: add an exmple that uses the API?
    usage = ''
      Although Neuropil is a library, its package also ships the example programs from the
      [introduction tutorial](https://pi-lar.gitlab.io/neuropil/tutorial.html).
      In the following example, we will use them to bootstrap a small neuropil network
      and send messages between two nodes.

      First, ${usageSnippets.run-shell}, then create a working directory.
      The examples write their logs and identities to the current directory:

      ```bash
      mkdir neuropil-demo
      cd neuropil-demo
      ```

      ##### Bootstrapping a network

      In a first terminal, start the bootstrap (infrastructure) node:

      ```bash
      neuropil_controller
      ```

      It prints the address other nodes can use to join the network:

      ```
      Bootstrap address: <fingerprint>:udp4:127.0.0.1:2345
      ```

      Other nodes can either use this address to join this exact network, or
      the wildcard address `*:udp4:localhost:2345` to join any network.

      ##### Receiving messages

      In a second terminal, start the receiver which joins the network through
      the bootstrap node:

      ```bash
      neuropil_receiver
      ```

      Back in the bootstrap node's terminal, a message announcing this
      connection will be printed:

      ```
      Bootstrap address: <fingerprint>:udp4:127.0.0.1:2345
      Joined: <receiver-public-key>...
      ```

      ##### Sending messages

      In a third terminal, start the sender which joins the same network as the
      receiver:

      ```bash
      neuropil_sender
      ```

      ```
      Bootstrap address: <fingerprint>:udp4:127.0.0.1:2345
      Joined: <receiver-public-key>...
      Joined: <sender-public-key>...
      ```

      Once connected, the sender will print each message it sends:

      ```
      Sent: msg 0
      Sent: msg 1
      Sent: msg 2
      ```

      and, once the nodes have discovered each other, the receiver prints the
      messages it gets:

      ```
      Received: msg 33
      Received: msg 34
      Received: msg 35
      ```

      > [!NOTE]
      > It might take a bit of time before the first message arrives at the
      > receiver because the nodes first need to discover each other in the mesh.

      For more details and in-depth examples, please see the
      [introduction tutorial](https://pi-lar.gitlab.io/neuropil/tutorial.html),
      the [API documentation](https://pi-lar.gitlab.io/neuropil/api.html),
      and the [`examples/` directory](https://gitlab.com/pi-lar/neuropil/-/tree/neuropil_1.0.2/examples)
      of the source repository.
    '';

    links = {
      website = "https://www.neuropil.org";
      source = "https://gitlab.com/pi-lar/neuropil";
      docs = "https://pi-lar.gitlab.io/neuropil";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Review = [
        "Neuropil"
        "Neuropil-DHT"
      ];
    };

    programs = {
      packages = with pkgs; [ neuropil ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      DURATION="240"

      pids=()

      start_process() {
        local name="$1"

        # NOTE: we use `stdbuf` to modify `stdout` so each line is immediately
        # printed, else there would be no output when the background processes are
        # killed after the timeout.
        #
        # See: https://www.gnu.org/software/coreutils/stdbuf
        timeout "$DURATION" stdbuf -oL "neuropil_$name" >$name.log 2>&1 &
        pids+=("$!")

        sleep 5
      }

      cleanup() {
        kill "''${pids[@]}" 2>/dev/null || true
        wait "''${pids[@]}" 2>/dev/null || true
      }
      trap cleanup EXIT

      start_process "controller"
      start_process "receiver"
      start_process "sender"

      # it takes a bit of times for nodes to discover each other
      for _i in $(seq 1 $DURATION); do
          if grep -q "Received: " receiver.log; then break; fi
          sleep 1
      done

      if ! grep -q "Received: " receiver.log; then
          cat *.log
          exit 1
      fi
    '';
  };
}
