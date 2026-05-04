{
  inputs,
  specialArgs,
  ...
}:

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
          inherit specialArgs;
          modules = modules;
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
          lib.attrValues (
            lib.mapAttrs (appName: app: ''
              mkdir -p $out/${appName}
              ${if app.icon or null != null then "cp ${app.icon} $out/${appName}/icon.svg" else ""}
            '') config.forge.apps
          )
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
          inherit (config.packages) _forge-config _forge-docs _forge-options;
          inherit appIcons;
          buildElmApplication = (inputs.ngi-forge.inputs.elm2nix.lib.elm2nix pkgs).buildElmApplication;
        };

        _forge-docs = pkgs.callPackage ../flake/packages/forge-docs.nix { };
      };
    };
}
