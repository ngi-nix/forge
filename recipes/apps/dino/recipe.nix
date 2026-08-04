{
  pkgs,
  ...
}:

{
  apps.dino = {
    displayName = "Dino";
    description = "Open source XMPP messaging application.";
    usage = ''
      Dino is an open-source chat client desktop application, based on the XMPP protocol. It focuses on providing a clean and reliable Jabber/XMPP experience while having your privacy in mind.
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [ "Dino-UX" ];
      Review = [ "Dino" ];
    };

    links = {
      source = "https://github.com/dino/dino";
      website = "https://dino.im";
    };

    programs = {
      mainPackage = pkgs.dino;
      runtimes.program.enable = true;
    };
  };
}
