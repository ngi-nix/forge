{
  pkgs,
  ...
}:

{
  apps.himalaya = {
    displayName = "Himalaya";
    description = "Command-line email client supporting IMAP, Maildir, and SMTP.";
    usage = ''
      Himalaya is a command-line email client that supports IMAP, Maildir, SMTP,
      and Sendmail backends with PGP encryption.

      #### Example

      List configured accounts

      ```
      himalaya account list
      ```

      List folders for the default account

      ```
      himalaya folder list
      ```

      List emails in the inbox

      ```
      himalaya envelope list
      ```

      Read an email by ID

      ```
      himalaya message read <id>
      ```

      Write and send a new email

      ```
      himalaya message write
      ```
    '';

    links = {
      website = "https://pimalaya.org";
      source = "https://github.com/pimalaya/himalaya";
    };

    ngi.grants = {
      Core = [
        "Pimalaya"
        "Pimalaya-PIM"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.himalaya
      ];

      runtimes.shell = {
        enable = true;
      };
    };
  };
}
