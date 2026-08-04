{
  lib,
  pkgs,
  ...
}:
let
  # https://github.com/NixOS/nixpkgs/pull/548013
  sbcl_2_4_6 = pkgs.sbcl_2_4_6.overrideAttrs (old: {
    postPatch = (lib.throwIf (lib.hasAttr "postPatch" old) "Nixpkgs pr 548013 is now in nixos-unstable, remove sbcl override in nyxt recipe.") ''
      rm tests/elf-sans-immobile.test.sh
    '';
  });
  nyxt = pkgs.nyxt.override { sbcl = sbcl_2_4_6; };
in
{
  apps.nyxt = {
    displayName = "Nyxt";
    description = "Infinitely extensible web browser with Lisp-based customization.";
    usage = ''
      Nyxt is a keyboard-driven web browser designed to be customized and extended
      using Common Lisp. It emphasizes privacy, efficiency, and user control.
    '';

    icon = ./icon.svg;

    links = {
      website = "https://nyxt.atlas.engineer";
      docs = "https://nyxt.atlas.engineer/documentation";
      source = "https://github.com/atlas-engineer/nyxt";
    };

    ngi.grants = {
      Entrust = [
        "Nyxt-Webextensions"
      ];
      Review = [
        "NyxtBrowser"
        "NyxtUserhosted"
      ];
    };

    programs = {
      mainPackage = nyxt;
      runtimes.program.enable = true;
    };

    test.programs.script = ''
      nyxt --version 2>&1 | grep -qE "[0-9]+\.[0-9]+"
    '';
  };
}
