{
  lib,
  pkgs,
  ...
}:
{
  apps.mustang = {
    displayName = "Mustang";
    description = "Full-featured desktop email, chat, video conference, calendar and contacts client.";
    categories = with lib.categories; [ Chat ];
    usage = ''
      Mustang is a full desktop client combining email, chat,
      video conferencing, calendar, contacts, and file sharing in one app. Data
      is stored and processed locally rather than passing through a server or
      cloud service, apart from the mail/calendar/contacts servers you connect
      to (IMAP, JMAP, CalDAV, CardDAV, EWS, and others).

      On first launch, add an account (mail, calendar, or contacts) to get
      started; autoconfiguration is supported for common providers.
    '';

    links = {
      website = "https://www.mustang.im";
      source = "https://github.com/mustang-im/mustang";
      docs = "https://github.com/mustang-im/mustang/wiki";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Mustang-UI"
        "Mustang-UX"
      ];
    };

    programs = {
      mainPackage = pkgs.mustang;
      packages = [ pkgs.mustang ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    # Mustang have no cli to run test with
  };
}
