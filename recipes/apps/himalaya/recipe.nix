{
  config,
  forge-lib,
  pkgs,
  ...
}:
let
  app = config.apps.himalaya;
  usageSnippets = forge-lib.snippets.usage app;
in
{
  pkgs.comodoro = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.comodoro;
    };
  };

  pkgs.himalaya = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.himalaya;
    };
  };

  pkgs.ortie = {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.ortie;
    };
  };

  apps.himalaya = {
    displayName = "Himalaya";
    description = "Command-line email client supporting IMAP, Maildir, and SMTP.";
    categories = with forge-lib.categories; [ Email ];
    usage = ''
      First, ${usageSnippets.run-shell}.

      The Himalaya environment bundles Pimalaya command-line tools for personal information management, email processing, synchronization, OAuth 2.0 authentication, and time management.

      More tools and roadmap of Pimalaya project [here](https://pimalaya.org/ecosystem/).

      ##### Himalaya

      Command-line email client supporting IMAP, JMAP, SMTP, Maildir, mbox, Gmail, and Microsoft Graph with PGP encryption.

      ```bash
      # Configure an account interactively
      himalaya configure

      # List configured accounts
      himalaya account list

      # List folders for the default account
      himalaya folder list

      # List emails in the inbox
      himalaya envelope list

      # Read an email by ID
      himalaya message read <id>

      # Write and send a new email
      himalaya message write
      ```

      ##### Neverest

      CLI utility to synchronize PIM collections: mail, contacts, and calendars across IMAP, SMTP, CardDAV, CalDAV, Google, Microsoft Graph, and local pimdir stores.

      ```bash
      # Probes and validates every configured source for an account
      neverest check -a <account>

      # Initializes an account replica in the pimdir store
      neverest init -a <account>

      # Performs dry-run synchronization
      neverest sync -a <account> --dry-run

      # Runs full bidirectional synchronization
      neverest sync -a <account>
      ```

      ##### Ortie

      CLI OAuth 2.0 token manager that handles account authorization grants, token refreshes, and interactive REPL sessions for email providers.

      ```bash
      # Authenticate and obtain a fresh OAuth 2.0 access token
      ortie auth

      # Display or refresh an existing token
      ortie token

      # Start an interactive OAuth REPL session
      ortie repl
      ```

      ##### Comodoro

      CLI timer and Pomodoro cycle manager with a background daemon, interactive real-time watcher, and desktop notifications.

      ```bash
      # Start a timer cycle
      comodoro start

      # Inspect current timer status
      comodoro get

      # Watch the timer countdown live
      comodoro watch

      # Pause or resume the timer
      comodoro pause
      comodoro resume
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
      Review = [ "Himalaya" ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        pkgs.himalaya
        pkgs.comodoro
        pkgs.neverest
        pkgs.ortie
      ];

      runtimes.shell.enable = true;
    };

    test.programs = {
      packages = [ pkgs.writableTmpDirAsHomeHook ];
      script = ''
        himalaya --version
        comodoro --version
        neverest --version
        ortie --version

        himalaya --help
        neverest --help
        comodoro --help
        ortie --help
      '';
    };
  };
}
