{
  lib,
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.zrythm;
in
{
  pkgs.zrythm = {
    build.identityBuilder = {
      enable = true;
      derivation = pkgs.pkgsOriginal.zrythm.overrideAttrs (old: {
        meta = old.meta // {
          mainProgram = "zrythm";
        };
      });
    };
  };
  apps.zrythm = {
    displayName = "Zrythm";
    description = "Digital audio workstation for composing, recording, editing, arranging, mixing and mastering audio and MIDI.";
    categories = with lib.categories; [ Development ];
    usage = ''
      Zrythm is a digital audio workstation (DAW), providing all the tools
      needed to compose, record, edit, arrange, mix, and master entire tracks
      of audio and MIDI data.

      See the [Docs](${recipe.links.docs}) for guidance on scanning
      and instantiating plugins, and importing audio/MIDI files.
    '';

    links = {
      website = "https://www.zrythm.org";
      source = "https://gitlab.com/zrythm/zrythm";
      docs = "https://manual.zrythm.org";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Commons = [
        "Zrythm"
      ];
    };

    programs = {
      mainPackage = pkgs.zrythm;
      packages = [ pkgs.zrythm ];
      runtimes.program.enable = true;
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      zrythm --version | grep -q "${pkgs.zrythm.version}"
    '';
  };
}
