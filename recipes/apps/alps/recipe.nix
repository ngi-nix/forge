{
  pkgs,
  ...
}:

{
  apps.alps = {
    displayName = "Alps";
    description = "Simple, extensible webmail client.";
    usage = ''
      Alps is a simple and extensible webmail client. It connects to an existing
      IMAP server for reading mail and an SMTP server for sending mail.

      Update `provider.imap.server` and `smtp.server` in the recipe to point to
      a real IMAP/SMTP server before using it.

      Webmail interface: [http://localhost:1323](http://localhost:1323)
    '';

    ngi.grants = {
      Commons = [ "Alps" ];
    };

    links = {
      website = "https://git.sr.ht/~migadu/alps";
      source = "https://git.sr.ht/~migadu/alps";
      docs = "https://git.sr.ht/~migadu/alps/tree/main/item/docs/CONFIGURATION.md";
    };

    services = {
      components.alps = {
        process = {
          configData."config.toml" = {
            text = ''
              [server]
              addr = ":1323"

              [provider]
              type = "imap"

              [provider.imap]
              server = "imaps://mail.example.com:993"

              [smtp]
              server = "smtps://mail.example.com:465"
            '';
            path = "config.toml";
          };
          command = pkgs.alps;
          argv = [
            "-config"
            "$XDG_CONFIG_HOME/config.toml"
          ];
          ports = [ "1323:1323" ];
        };
      };

      runtimes = {
        container.enable = true;
        nixos.enable = true;
      };
    };

    test.services.script = ''
      curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"
      $curl -fs localhost:1323/ | grep -i "alps"
    '';
  };
}
