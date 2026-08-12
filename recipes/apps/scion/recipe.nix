{
  pkgs,
  ...
}:

{
  pkgs.scion = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.scion;
    };
  };

  apps.scion = {
    displayName = "SCION";
    description = "SCION: a next-generation inter-domain routing architecture.";
    usage = ''
      #### Intro

      **WIP**

      Documentation
      Usage Examples:
      https://github.com/netsys-lab/bittorrent-over-scion#usage
      Build from source/Development:
      https://github.com/scionproto/scion#build-from-sources

      https://github.com/scionproto/scion/wiki

      https://apps.scion.org/
    '';

    icon = ./icon.svg;

    links = {
      website = "https://www.scion.org";
      docs = "https://docs.scion.org";
      source = "https://github.com/scionproto/scion";
    };

    ngi.grants = {
      Commons = [
        "SCION-IP-gateway"
        "SelectCast"
      ];
      Core = [
        "SCION-1M"
        "Verified-SCION-router"
        "SCION-router-codealignment"
        "SCION-IPFS"
      ];
      Entrust = [
        "SCION-proxy"
      ];
      Review = [
        "SCION-Rains"
        "SCION-Swarm"
        "SCION-geo"
        "TrustING"
      ];
    };

    programs = {
      runtimes.shell.enable = true;
      packages = [
        pkgs.scion
      ];
    };

    test.programs.script = ''
      # FIXME
    '';
  };
}
