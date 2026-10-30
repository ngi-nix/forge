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
    build.builders.identity = {
      enable = true;
      # TODO: remove preFixup override once https://github.com/NixOS/nixpkgs/pull/570791 is in nixos-unstable
      derivation = pkgs.pkgsOriginal.zrythm.overrideAttrs (old: {
        preFixup = ''
          gappsWrapperArgs+=(
            --prefix GSETTINGS_SCHEMA_DIR : "$out/share/gsettings-schemas/${old.pname}-${old.version}/glib-2.0/schemas/"
          )
        '';
        meta = old.meta // {
          mainProgram = "zrythm";
        };
      });
    };
  };
  apps.zrythm = {
    displayName = "Zrythm";
    description = "Digital audio workstation for composing, recording, editing, arranging, mixing and mastering audio and MIDI.";
    categories = with lib.categories; [ Audio ];
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
