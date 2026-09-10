{
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.ricochet-refresh;
in
{
  pkgs.ricochet-refresh = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.ricochet-refresh;
    };
  };

  apps.ricochet-refresh = {
    displayName = "Ricochet Refresh";
    description = "Secure chat without DNS or WebPKI.";
    usage = ''
      Ricochet Refresh is an instant messenger that establishes a direct,
      peer-to-peer connection between you and your contacts over the Tor
      network, without a central server and without revealing your identity or
      IP address to anyone you talk to.

      Security and anonymity are difficult, deep topics — evaluate your own
      risks and threats, and don't rely on Ricochet Refresh alone for safety.

      See the [Website](${recipe.links.website}) for more info and FAQs.
    '';

    links = {
      website = "https://www.ricochetrefresh.net";
      source = "https://github.com/blueprint-freespeech/ricochet-refresh";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Rico-UX"
      ];
      Review = [
        "Rico"
      ];
    };

    programs = {
      mainPackage = pkgs.ricochet-refresh;
      packages = [ pkgs.ricochet-refresh ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    # ricochet-refresh doesn't have any cli to test

  };
}
