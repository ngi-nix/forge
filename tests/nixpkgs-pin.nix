{
  inputs ? (
    let
      f = builtins.getFlake (toString ../.);
    in
    f.inputs // { self = f; }
  ),
  system ? builtins.currentSystem,
}:
let
  inherit (inputs) nixpkgs flake-parts;
  lib = nixpkgs.lib;
  flakeModules =
    (import ../forge/modules.nix {
      inherit inputs lib;
      flake-parts-lib = flake-parts.lib;
    }).flake.flakeModules;

  # Evaluate Forge module system with test package and app definitions
  eval = flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ system ];
    imports = [
      flakeModules.base
    ];
    perSystem = { pkgs, ... }: {
      forge = {
        enable = true;
        pkgs = {
          # Scenario 1: Identity builder pointing to an older Nixpkgs revision
          # Current Nixpkgs has hello 2.12.3. Pinned revision (2025-05-20) has 2.12.1.
          pinned-hello = {
            nixpkgsPin = {
              rev = "2795c506fe8fb7b03c36ccb51f75b6df0ab2553f";
              narHash = "sha256-W7lqHp0qZiENCDwUZ5EX/lNhxjMdNapFnbErcbnP11Q=";
              date = "2025-05-20";
              reason = "Test identityBuilder with pinned Nixpkgs";
            };
            build.identityBuilder = {
              enable = true;
              attribute = "hello";
            };
          };

          # Scenario 1b: Identity builder using function for derivation
          pinned-hello-fn = {
            nixpkgsPin = {
              rev = "2795c506fe8fb7b03c36ccb51f75b6df0ab2553f";
              narHash = "sha256-W7lqHp0qZiENCDwUZ5EX/lNhxjMdNapFnbErcbnP11Q=";
              date = "2025-05-20";
              reason = "Test identityBuilder with function derivation";
            };
            build.identityBuilder = {
              enable = true;
              derivation = p: p.hello;
            };
          };

          # Scenario 2: Standard builder using compiler toolchain from pinned Nixpkgs
          pinned-builder = {
            version = "1.0.0";
            description = "Test package built with pinned toolchain.";
            license = lib.licenses.mit;
            source.path = ./.;
            nixpkgsPin = {
              rev = "2795c506fe8fb7b03c36ccb51f75b6df0ab2553f";
              narHash = "sha256-W7lqHp0qZiENCDwUZ5EX/lNhxjMdNapFnbErcbnP11Q=";
              date = "2025-05-20";
              reason = "Test standardBuilder with pinned Nixpkgs";
            };
            build = {
              standardBuilder = {
                enable = true;
                packages.build = p: [ p.hello ];
              };
              extraAttrs = {
                dontUnpack = true;
                installPhase = ''
                  mkdir -p $out/bin
                  echo '#!/bin/sh' > $out/bin/pinned-builder
                  echo 'hello from pinned builder' >> $out/bin/pinned-builder
                  chmod +x $out/bin/pinned-builder
                '';
              };
            };
          };

          # Scenario 3: Python package builder with pinned dependencies
          pinned-python = {
            version = "0.1.0";
            description = "Test python package with pinned dependencies.";
            license = lib.licenses.mit;
            source.path = ./.;
            nixpkgsPin = {
              rev = "2795c506fe8fb7b03c36ccb51f75b6df0ab2553f";
              narHash = "sha256-W7lqHp0qZiENCDwUZ5EX/lNhxjMdNapFnbErcbnP11Q=";
              date = "2025-05-20";
              reason = "Test pythonPackageBuilder with pinned Nixpkgs";
            };
            build = {
              pythonPackageBuilder = {
                enable = true;
                packages.dependencies = p: [ p.python3Packages.wheel ];
              };
              extraAttrs = {
                dontUnpack = true;
                installPhase = "mkdir -p $out";
              };
            };
          };
        };

        apps = {
          test-pinned-app = {
            displayName = "Test Pinned App";
            description = "Test app consuming pinned packages.";
            programs = {
              packages = [
                eval.packages.${system}.pkgs."pinned-hello"
                eval.packages.${system}.pkgs."pinned-builder"
              ];
              runtimes.shell.enable = true;
            };
          };
        };
      };
    };
  };

  testPkgs = eval.packages.${system};
in
{
  inherit eval;
  pinnedHello = testPkgs.pkgs."pinned-hello";
  pinnedBuilder = testPkgs.pkgs."pinned-builder";
  pinnedApp = testPkgs.apps."test-pinned-app";

  # Assertions to verify the pins behave as expected
  checks = {
    # Pinned hello should be 2.12.1 (from the pinned revision), not 2.12.3 (from global nixpkgs)
    helloVersion = testPkgs.pkgs."pinned-hello".version;
    helloVersionIsPinned = testPkgs.pkgs."pinned-hello".version == "2.12.1";
    helloFnVersionIsPinned = testPkgs.pkgs."pinned-hello-fn".version == "2.12.1";
    builderVersion = testPkgs.pkgs."pinned-builder".version;
    builderVersionIsPinned = testPkgs.pkgs."pinned-builder".version == "1.0.0";
    builderBuildInputPinnedHello =
      (builtins.elemAt testPkgs.pkgs."pinned-builder".nativeBuildInputs 0).version == "2.12.1";
    pythonPackageHasPinnedDep = builtins.elem "wheel" (
      map (d: d.pname or d.name) testPkgs.pkgs."pinned-python".propagatedBuildInputs
    );
  };
}
