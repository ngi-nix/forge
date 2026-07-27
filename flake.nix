{
  description = "NGI Forge";

  nixConfig = {
    extra-substituters = [ "https://ngi-forge.cachix.org" ];
    extra-trusted-public-keys = [
      "ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0="
    ];
  };

  inputs = {
    # Rervert nixpkgs URL back to the official repo once
    # https://github.com/NixOS/nixpkgs/pull/540857
    # is merged and is present in nixos-unstable branch.
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:imincik/nixpkgs/nixos-unstable+pr-540857";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elm2nix = {
      url = "github:dwayne/elm2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-utils = {
      url = "github:imincik/nix-utils";
      flake = false;
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nimi = {
      url = "github:ngi-nix/nimi/ngi-patches";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:

    let
      flake =
        flake-parts.lib.mkFlake
          {
            inherit inputs;
          }
          (flakeArgs: {
            # Uncomment this to enable flake-parts debug.
            # https://flake.parts/options/flake-parts.html?highlight=debug#opt-debug
            # debug = true;

            systems = [
              "x86_64-linux"
              # "aarch64-linux"
              # "aarch64-darwin"
              # "x86_64-darwin"
            ];

            imports = [
              ./forge/modules.nix
              ./flake/develop
              ./flake/packages.nix
              ./flake/checks.nix
              ./flake/templates.nix
            ];

            # Export the flake configuration to ease exploration in `nix repl .`.
            #
            # Remark(clarity): like all `unknown` flake outputs,
            # this currently raise a warning in `nix flake check`:
            # > warning: unknown flake output 'flakeConfig'
            # Issue: https://github.com/NixOS/nix/issues/6381
            flake.flakeConfig = flakeArgs.config;
            flake.flakeOptions = flakeArgs.options;
            flake.maintainerList = ./maintainers/maintainer-list.nix;

            perSystem =
              { system, ... }:
              {
                forge = {
                  repositoryUrl = self.sourceInfo.url or "github:ngi-nix/forge";
                  maintainerLists = [ self.maintainerList ];
                };
              };
          });

      # The `apps` output is disallowed because we are exposing `apps` through `packages.${system}`.
      # `flake-parts` creates empty `apps.${system}` by default, so we filter out empty sets.
      apps = inputs.nixpkgs.lib.filterAttrs (_: v: v != { }) (flake.apps or { });
    in
    if apps != { } then
      throw ''
        The top-level `apps` flake output is disallowed in this project.
        We instead treat `apps` as packages and expose them via `packages.''${system}`
        Please remove any direct `apps` definitions which were mistakenly added.
      ''
    else
      builtins.removeAttrs flake [ "apps" ];
}
