{
  inputs,
  specialArgs,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  imports = [
    ./assertions-warnings.nix
    ./builders/shared.nix
    ./builders/standard-builder
    ./builders/go-builder
    ./builders/npm-package-builder
    ./builders/pnpm-package-builder
    ./builders/python-app-builder
    ./builders/python-package-builder
    ./builders/rust-package-builder
  ];

  options = {
    perSystem = mkPerSystemOption (
      {
        config,
        system,
        pkgs,
        #specialArgs,
        ...
      }:
      {
        options = {
          forge.packages = lib.mkOption {
            default = { };
            description = ''
              List of packages to include in forge.

              Each package uses one of the available builders.
              Only one builder can be enabled per package by setting build.<builder>.enable = true.
            '';
            type = lib.types.attrsOf (
              lib.types.submoduleWith {
                specialArgs = specialArgs // {
                  rootConfig = config;
                  inherit system pkgs;
                };
                modules = [ packages/package.nix ];
              }
            );
          };
        };

        # Config section is now provided by builder modules
        config =
          let
            cfg = lib.attrValues config.forge.packages;

            # Process warnings: filter to get active warnings (condition = true), then show them
            activeWarnings = lib.filter (x: x.condition) config.warnings;
            showWarnings = lib.foldr (w: acc: lib.warn w.message acc) true activeWarnings;

            # Process assertions: filter to get failed assertions (condition = false)
            failedAssertions = lib.filter (x: !x.condition) config.assertions;
            assertionMessages = lib.concatMapStringsSep "\n" (x: "- ${x.message}") failedAssertions;
          in
          {
            forge.packages = (
              inputs.ngi-forge.lib.loadRecipes {
                rootDir = inputs.ngi-forge + "/recipes/packages";
                sourceUrl =
                  { path }:
                  "https://github.com/ngi-nix/forge/blob/${inputs.ngi-forge.lib.sourceInfoRef inputs.ngi-forge}/recipe/packages/${path}";
              }
            );

            # Collect warnings from packages
            warnings = lib.flatten (
              map (pkg: [
                {
                  condition = pkg.source.hash == "" && pkg.source.path == null;
                  message = ''
                    Package '${pkg.name}': source.hash is empty.
                    Correct hash will be printed in the error message when package is built.
                  '';
                }
                {
                  condition = pkg.license == [ ];
                  message = ''
                    Package '${pkg.name}': license is empty.
                  '';
                }
              ]) cfg
            );

            # Collect assertions from packages
            assertions = lib.flatten (
              map (
                pkg:
                let
                  builders = lib.filterAttrs (name: _: lib.hasSuffix "Builder" name) pkg.build;
                  builderNames = map (name: "build." + name) (lib.attrNames builders);

                  enabledBuilders = lib.filterAttrs (_: b: b.enable) builders;
                  enabledBuilderNames = map (name: "build." + name) (lib.attrNames enabledBuilders);

                  enabledBuildersCount = lib.length enabledBuilderNames;
                in
                [
                  {
                    condition = !(pkg.source.git == null && pkg.source.url == null && pkg.source.path == null);
                    message = ''
                      Package '${pkg.name}': one of sources options must be defined.
                      Available options: source.git, source.url, or source.path.
                    '';
                  }
                  {
                    condition = !(enabledBuildersCount != 1);
                    message = ''
                      Package '${pkg.name}': only one builder can be enabled at a time.
                      Enabled options: ${lib.concatStringsSep ", " enabledBuilderNames}.
                    '';
                  }
                  {
                    condition = !(enabledBuildersCount == 0);
                    message = ''
                      Package '${pkg.name}': one of builder options must be enabled.
                      Available options: ${lib.concatStringsSep ", " builderNames}.
                    '';
                  }
                ]
              ) cfg
            );

            # Evaluation check: show warnings first, then throw on failed assertions
            _module.check =
              if showWarnings then
                if failedAssertions != [ ] then throw "\nFailed assertions:\n${assertionMessages}" else true
              else
                true;
          };
      }
    );
  };
}
