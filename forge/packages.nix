{ inputs, flake-parts-lib, ... }:

{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      forgeModules = [
        ./modules/apps
        ./modules/packages.nix
      ];

      evalForgeModules =
        modules:
        lib.evalModules {
          modules = modules;
          specialArgs = { inherit flake-parts-lib inputs; };
        };

      forgeOptionsDoc =
        modules:
        pkgs.nixosOptionsDoc {
          warningsAreErrors = false;
          options = lib.removeAttrs (evalForgeModules modules).options [ "_module" ];
          transformOptions =
            opt:
            opt
            // {
              name = lib.removePrefix "perSystem.forge." opt.name;
              declarations = [ ];
              visible = lib.match ("^perSystem\\.forge\\.(apps|packages)(\\..+)?") opt.name != null;
            };
        };

      forgeOptions = forgeOptionsDoc forgeModules;

      # Collect app icons into a derivation
      appIcons = pkgs.runCommand "app-icons" { } ''
        mkdir -p $out
        ${lib.concatStringsSep "\n" (
          map (
            app:
            let
              # Remove -app suffix for directory name
              appDir = lib.removeSuffix "-app" app.name;
            in
            ''
              mkdir -p $out/${appDir}
              ${if app.icon or null != null then "cp ${app.icon} $out/${appDir}/icon.svg" else ""}
            ''
          ) config.forge.apps
        )}
      '';
    in
    {
      packages = {
        _forge-config = pkgs.writeTextFile {
          name = "forge-config.json";
          text = builtins.toJSON config.forge;
        };

        _forge-options = pkgs.runCommand "options.json" { } ''
          cp ${forgeOptions.optionsJSON}/share/doc/nixos/options.json $out
        '';

        _forge-ui = pkgs.callPackage ../ui/package.nix {
          inherit (config.packages) _forge-config _forge-options;
          inherit appIcons;
          buildElmApplication = (inputs.elm2nix.lib.elm2nix pkgs).buildElmApplication;
        };
      };
    };
}
