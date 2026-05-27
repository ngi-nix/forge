{
  flake-inputs ? import (fetchTarball {
    url = "https://github.com/fricklerhandwerk/flake-inputs/tarball/4.1.0";
    sha256 = "1j57avx2mqjnhrsgq3xl7ih8v7bdhz1kj3min6364f486ys048bm";
  }),
  flake ? flake-inputs.import-flake { src = ./.; },
  inputs ? flake.inputs,
  system ? builtins.currentSystem,
  pkgs ? import inputs.nixpkgs {
    config = { };
    overlays = [ ];
    inherit system;
  },
  lib ? import "${inputs.nixpkgs}/lib",
}:
let
  default = lib.makeScope pkgs.newScope (def: {
    inherit
      lib
      pkgs
      flake
      system
      inputs
      default # recurse scope
      ;

    nimi-def = import inputs.nimi-def { inherit pkgs; };
    nimi = def.nimi-def.nimi;
    nimiLib = def.nimi.passthru;

    # requires debug to be enabled in flake
    debug = flake.outputs.allSystems.${system};

    inherit (default.debug) forge;

    # derivations
    forgeApps = lib.filterAttrs (
      name: value: lib.hasSuffix "-app" name
    ) flake.outputs.packages.${system};
    forgePkgs = flake.outputs.packages.${system};
    shells = flake.outputs.devShells.${system};
  });
in
default // flake.outputs.packages.${system}
