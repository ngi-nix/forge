{
  pkgs,
  ...
}:

{
  apps.dutctl = {
    displayName = "DUT Control";
    description = "Unified device management for open firmware development.";

    usage = ''
      DUT Control is a tool that provides a unified interface to interact with development boards and test fixtures across platforms.

      #### Components

      - **dutagent**: Service daemon that manages physical devices (default port: 1024)
      - **dutctl**: CLI client for interacting with agents
      - **dutserver**: Central proxy for multi-agent setups (experimental)

      #### Test devices

      The [example agent configuration](https://github.com/BlindspotSoftware/dutctl/blob/710bbcd16264e62af932698a229f9be2f83f6286/contrib/dutagent-cfg-example.yaml) includes three simulated devices (device1, device2, device3) using [dummy modules](https://github.com/BlindspotSoftware/dutctl/blob/710bbcd16264e62af932698a229f9be2f83f6286/pkg/module/dummy/README.md).
      Provide your own YAML config to manage real hardware.

      #### Basic Usage

      First, start the agent service through one of the service runtimes.
      For instructions on how to do so, click the `Run` button on the top right of this page.

      Once the agent is up, verify that the device can connect to it:

      ```
      dutctl device1 status
      ```

      If it's successful, you should receive: `Hello from dummy status module`.

      Next, start the console repeat mode:

      ```
      dutctl device2 repeat
      ```

      Each word you type should be echoes back into the terminal.
      To exit, type 2 words.
    '';

    links = {
      docs = "https://github.com/BlindspotSoftware/dutctl/blob/main/docs/README.md";
      source = "https://github.com/BlindspotSoftware/dutctl";
      website = "https://github.com/BlindspotSoftware/dutctl";
    };

    ngi.grants = {
      Entrust = [ "DUT-Control" ];
    };

    programs = {
      packages = with pkgs; [
        dutctl
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    services = {
      components.dutagent = {
        command = "${pkgs.dutctl}/bin/dutagent";
        argv = [
          "-a" # address
          "0.0.0.0:1024"
          "-c" # path to config
          "/var/lib/dutagent/config.yaml"
        ];
        ports = [
          "1024:1024"
        ];
        configData."dutagent/config.yaml" = {
          source = ./dutagent-cfg-example.yaml;
          path = "dutagent/config.yaml";
        };
        preStart = ''
          echo "Installing configuration files ..."
          cp -v ''$XDG_CONFIG_HOME/dutagent/config.yaml /var/lib/dutagent/config.yaml
        '';
      };

      runtimes = {
        container = {
          enable = true;
          components.dutagent.packages = with pkgs; [
            bash # for entering the container
            coreutils # mkdir, echo, ...
            dutctl
          ];
        };

        nixos = {
          enable = true;
          packages = with pkgs; [
            dutctl
          ];
        };
      };
    };

    test.services.script = ''
      # wait for agent to become ready
      for i in $(seq 1 10); do
        dutctl list 2>/dev/null | grep -q device1 && break
        [ "$i" -eq 10 ] && { echo "FAIL: agent timed out"; exit 1; }
        sleep 1
      done
      echo "PASS: agent ready"

      # verify device status
      dutctl device1 status > status.out
      grep -q "Hello from dummy status module" status.out
      echo "PASS: device1 status"
    '';
  };
}
