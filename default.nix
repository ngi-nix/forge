{
  flake-inputs ? import (fetchTarball {
    url = "https://github.com/fricklerhandwerk/flake-inputs/tarball/4.1.0";
    sha256 = "1j57avx2mqjnhrsgq3xl7ih8v7bdhz1kj3min6364f486ys048bm";
  }),
  flake ? flake-inputs.import-flake { src = ./.; },
  inputs ? flake.inputs,
  system ? builtins.currentSystem,
  nixpkgs ? import inputs.nixpkgs {
    config = { };
    overlays = [ ];
    inherit system;
  },
  lib ? import "${inputs.nixpkgs}/lib",
}:
let
  drvToAttrs =
    drv:
    builtins.removeAttrs drv [
      "drvPath"
      "outPath"
      "outputName"
      "name"
      "type"
      "system"
    ];
  default = lib.makeScope nixpkgs.newScope (def: {
    inherit
      lib
      flake
      nixpkgs
      system
      inputs
      default # recurse scope
      ;

    nimi-def = import inputs.nimi { pkgs = nixpkgs; };
    nimi = def.nimi-def.nimi;
    nimiLib = def.nimi.passthru;

    # requires debug to be enabled in flake
    debug = flake.outputs.flakeConfig.allSystems.${system};

    inherit (default.debug) forge;

    apps = drvToAttrs flake.outputs.packages.${system}.apps;
    pkgs = drvToAttrs flake.outputs.packages.${system}.pkgs;
    _forge = drvToAttrs flake.outputs.packages.${system}._forge;

    shells = flake.outputs.devShells.${system};
  });
in
default // flake.outputs.legacyPackages.${system}
