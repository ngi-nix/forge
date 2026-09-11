{
  lib,
  pkgs,
  ...
}:

{
  apps.comaps = {
    displayName = "CoMaps";
    description = "A community-led fork of Organic Maps focused on free and open navigation with privacy.";
    categories = with lib.categories; [ Network ];

    usage = ''
      CoMaps is a navigation app focused on speed, privacy, battery efficiency and minimization of network utilization.
      It uses offline maps that enable navigation in places far from civilization or in cities with complex traffic networks.

      To learn more about what CoMaps does best, see [here](https://www.comaps.app/support/what-does-comaps-do-best/) and to see CoMaps sources of data, see [here](https://www.comaps.app/support/which-data-sources-does-comaps-use/).
      More general suport can be found [here](https://www.comaps.app/support/).
    '';

    links = {
      website = "https://www.comaps.app/";
      docs = "https://www.comaps.app/support/";
      source = "https://codeberg.org/comaps/comaps";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "CoMaps"
      ];
    };

    programs = {
      runtimes.program.enable = true;
      mainPackage = pkgs.comaps;
    };

    test.programs.script = ''
      export HOME=$(mktemp -d)
      CoMaps -version | grep "CoMaps"
    '';
  };
}
