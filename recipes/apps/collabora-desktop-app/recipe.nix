{
  pkgs,
  ...
}:

{
  apps.collabora-desktop = {
    displayName = "Collabora Office";
    description = "Collaborative Office for desktop, based on LibreOffice technology.";
    usage = ''
      Collabora Office is a powerful LibreOffice-based office suite that supports all major document, spreadsheet, presentation, and drawing file formats. It is an initial version of [Collabora Online](https://www.collaboraonline.com/collabora-online/) ported to desktop, sharing the same underlying code.

      Collabora Office allows working with documents locally and collaboration features are [planned](https://www.reddit.com/r/CollaboraOffice/comments/1pg5i04/comment/nswivuy/) in upcoming versions.

      If a multi-user real-time collaboration experience is required, please use **Collabora Online**, instead of the desktop version.

      If syncing to nextcloud without real-time collaboration is enough you can set up the [Nextcloud desktop sync client](https://docs.nextcloud.com/server/latest/user_manual/en/desktop/installation.html), as [recommended by Collabora](https://forum.collaboraonline.com/t/cannot-open-files-in-the-desktop-version-from-mapped-drives/4644/2).

      See also: [Frequently Asked Questions](https://collaboraonline.github.io/post/faq/) and the [Collabora Online forum](https://forum.collaboraonline.com/).
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Follow-me-slideshow"
        "InfiniteCanvas"
      ];
      Entrust = [ "LO-Accessible" ];
    };

    links = {
      source = "https://github.com/CollaboraOnline/online";
      website = "https://www.collaboraonline.com/collabora-office/";
    };

    programs = {
      mainPackage = pkgs.collabora-desktop;
      runtimes.program.enable = true;
    };
  };
}
