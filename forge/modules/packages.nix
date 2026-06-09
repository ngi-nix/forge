{ config, lib, ... }:
{
  imports = [
    ./assertions-warnings.nix
  ];

  options.forge = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [
        (
          { specialArgs, ... }@forgeArgs:
          {
            config = {
              # Convenient alias to use `packages` instead of `config.packages`
              _module.args.packages = forgeArgs.config.packages;
            };
            options.packages = lib.mkOption {
              default = { };
              description = ''
                Packages indexed by their `pname`.

                Each package uses one of the available builders.
                Only one builder can be enabled per package by setting build.<builder>.enable = true.
              '';
              type = lib.types.attrsOf (
                lib.types.submoduleWith {
                  specialArgs = specialArgs // {
                    forgeOptions = forgeArgs.options;
                  };
                  modules = [
                    builders/shared.nix
                    packages/package.nix
                  ];
                }
              );
            };
          }
        )
      ];
    };
  };

  # Config section is now provided by builder modules
  config =
    let
      # Process warnings: filter to get active warnings (condition = true), then show them
      activeWarnings = lib.filter (x: x.condition) config.warnings;
      showWarnings = lib.foldr (w: acc: lib.warn w.message acc) true activeWarnings;

      # Process assertions: filter to get failed assertions (condition = false)
      failedAssertions = lib.filter (x: !x.condition) config.assertions;
      assertionMessages = lib.concatMapStringsSep "\n" (x: "- ${x.message}") failedAssertions;
    in
    {
      packages = lib.mapAttrs' (
        packageName: package: lib.nameValuePair package.outputName package.result.derivation
      ) config.forge.packages;

      # Collect warnings from packages
      warnings = lib.flatten (
        map (pkg: [
          {
            condition = pkg.source.hash == "" && pkg.source.path == null;
            message = ''
              Package '${pkg.pname}': source.hash is empty.
              Correct hash will be printed in the error message when package is built.
            '';
          }
          {
            condition = pkg.license == [ ];
            message = ''
              Package '${pkg.pname}': license is empty.
            '';
          }
        ]) (lib.attrValues config.forge.packages)
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
                Package '${pkg.pname}': one of sources options must be defined.
                Available options: source.git, source.url, or source.path.
              '';
            }
            {
              condition = !(enabledBuildersCount != 1);
              message = ''
                Package '${pkg.pname}': only one builder can be enabled at a time.
                Enabled options: ${lib.concatStringsSep ", " enabledBuilderNames}.
              '';
            }
            {
              condition = !(enabledBuildersCount == 0);
              message = ''
                Package '${pkg.pname}': one of builder options must be enabled.
                Available options: ${lib.concatStringsSep ", " builderNames}.
              '';
            }
          ]
        ) (lib.attrValues config.forge.packages)
      );

      # Evaluation check: show warnings first, then throw on failed assertions
      _module.check =
        if showWarnings then
          if failedAssertions != [ ] then throw "\nFailed assertions:\n${assertionMessages}" else true
        else
          true;
    };
}
