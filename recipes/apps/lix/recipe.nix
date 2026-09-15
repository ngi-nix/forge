{
  lib,
  pkgs,
  ...
}:

{
  pkgs.lix = {
    # TODO expose all of lixPackageSets, once https://github.com/ngi-nix/forge/issues/829 is solved
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.lixPackageSets.stable.lix;
    };
  };

  apps.lix = {
    displayName = "Lix";
    description = "A modern and fast implementation of the Nix package manager.";
    categories = with lib.categories; [ Development ];
    usage = ''
      Lix is a modern, delicious implementation of the Nix package manager, focused on correctness, usability, and growth – and committed to doing right by its community.

      **Note:** Prefer installing Lix following the official instructions at [https://lix.systems/install/](https://lix.systems/install/).
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [ "RPC-framework" ];
    };

    links = {
      website = "https://lix.systems";
      docs = "https://wiki.lix.systems/books";
      source = "https://git.lix.systems/lix-project/lix";
    };

    programs = {
      mainPackage = pkgs.lix;
      packages = [ pkgs.lix ];

      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };
  };
}
