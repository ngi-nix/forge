{
  forge-lib,
  lib,
  pkgs,
  ...
}:

let
  setBroken = {
    # Depends on vulnerable pybars3: https://github.com/NixOS/nixpkgs/pull/581431
    # Could potentiall by solved by: https://github.com/yaqwsx/KiKit/issues/948
    broken = true;
  };
in

{
  pkgs.kikit = setBroken // {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.kikit;
    };
  };
  pkgs.kicadAddons-kikit = setBroken // {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.kicadAddons.kikit;
    };
  };
  pkgs.kicadAddons-kikit-library = setBroken // {
    build.builders.identity = {
      enable = true;
      derivation = pkgs.pkgsOriginal.kicadAddons.kikit-library;
    };
  };

  apps.kikit = setBroken // {
    displayName = "KiKit";
    description = "Tooling for automation of production of PCB designed in KiCAD.";
    categories = with forge-lib.categories; [
      Development
      Electronics
    ];
    usage = ''
      KiKit is a Python library, KiCAD plugin, and a CLI tool to automate several tasks in a standard KiCAD workflow.

      Get started here https://yaqwsx.github.io/KiKit/latest/panelization/intro/.
    '';

    links = {
      website = "https://yaqwsx.github.io/KiKit/latest/";
      docs = "https://yaqwsx.github.io/KiKit/latest/cli/";
      source = "https://github.com/yaqwsx/KiKit";
    };

    ngi.grants = {
      Entrust = [ "KiKit" ];
    };

    icon = ./icon.svg;

    programs = {
      packages = with pkgs; [
        kikit
        kicadAddons-kikit
        kicadAddons-kikit-library
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      kikit --version | grep -q "${pkgs.kikit.version}"
    '';
  };
}
