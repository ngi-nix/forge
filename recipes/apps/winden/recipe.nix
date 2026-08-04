{
  pkgs,
  config,
  ...
}:

{
  apps.winden = {
    displayName = "Winden";
    description = "Securely transfer files between computers via the browser.";
    usage = ''
      > [!NOTE]
      > Be aware, this is a **Beta version**, which might have some [issues](https://winden.app/faq) or not work as expected in all browsers.

      Winden is a free web application for secure, fast, and easy file transfers between devices in real-time. Winden is identity-free, meaning that senders and receivers don't need to know each other's identity to use it, or to reveal their identity to winden.

      Does not require people to sign up or log in and also cannot access any files you send, as they are end-to-end encrypted. Files are never stored on winden's servers and transfers happen in real-time. While these aspects ensure the app is more private and secure, it means that both the sender and receiver need to be online at the same time. **Learn more about how Winden works in the [FAQ](https://winden.app/faq)**.

      Based on the [Magic Wormhole protocol](https://magic-wormhole.readthedocs.io/), Winden was developed to scale the protocol without compromising its security and make it ready for web-usage.

      Try it out at [winden.app](https://winden.app) or on the Forge by following the Run instructions.

      > [!TIP]
      > If you do not have two separate machines to test file transfers, you can simply open Winden in two separate browser tabs or windows on the same machine to act as the sender and receiver.
    '';

    links = {
      website = "https://winden.app";
      source = "https://github.com/LeastAuthority/winden";
    };

    ngi.grants = {
      Review = [ "Winden-MWH-Dilation" ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [ pkgs.winden ];
    };

    services = {
      components.web = {
        process.command = "${pkgs.caddy}/bin/caddy";
        process.argv = [
          "run"
          "--adapter"
          "caddyfile"
          "--config"
          "${pkgs.writeText "Caddyfile" ''
            :8080 {
              root * ${pkgs.winden}/share/winden

              handle_path /mailbox* {
                reverse_proxy mailbox:4000
              }

              handle_path /relay* {
                reverse_proxy transit:4002
              }

              handle {
                try_files {path} /index.html
                file_server
              }
            }
          ''}"
        ];
        process.ports = [ "8080:8080" ];
      };

      # Reuse mailbox component from the magic-wormhole app recipe
      components.mailbox = {
        process = config.apps.magic-wormhole.services.components.mailbox.process;
      };

      # Winden requires websocket support in the transit relay
      components.transit = {
        process = config.apps.magic-wormhole.services.components.transit.process // {
          argv = [
            "-n"
            "transitrelay"
            "--port=tcp:4001"
            "--websocket=tcp:4002"
          ];
          ports = [
            "4001:4001"
            "4002:4002"
          ];
        };
      };

      runtimes.container.enable = true;
      runtimes.nixos = {
        enable = true;
        nixosConfig = {
          networking.hosts."127.0.0.1" = [
            "mailbox"
            "transit"
          ];
        };
      };
    };

    test.services = {
      packages = [
        (pkgs.python3.withPackages (ps: [ ps.selenium ]))
        pkgs.chromium
        pkgs.chromedriver
      ];
      script = ''
        curl --retry 10 --retry-max-time 120 --retry-all-errors http://localhost:8080 | grep -q "Winden"

        python3 ${
          pkgs.replaceVars ./test.py {
            inherit (pkgs) chromedriver chromium;
          }
        }
      '';
    };
  };
}
