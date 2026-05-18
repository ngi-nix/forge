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

      forgeApps = config.forge.apps;
      forgeOptions = forgeOptionsDoc forgeModules;

      # Collect app icons into a derivation
      appIcons = pkgs.runCommand "app-icons" { } ''
        mkdir -p $out
        ${lib.concatStringsSep "\n" (
          map (app: ''
            mkdir -p $out/${app.name}
            ${if app.icon or null != null then "cp ${app.icon} $out/${app.name}/icon.svg" else ""}
          '') forgeApps
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
          inherit (config.packages)
            _forge-config
            _forge-docs
            _forge-options
            ;
          inherit appIcons;
          buildElmApplication = (inputs.elm2nix.lib.elm2nix pkgs).buildElmApplication;
          highlight-js = pkgs.callPackage ../flake/packages/highlight-js.nix { };
        };

        _forge-ui-dev = pkgs.callPackage ../flake/packages/forge-ui-dev.nix {
          inherit (config.packages)
            _forge-ui
            _forge-docs
            _forge-options
            ;
          highlight-js = pkgs.callPackage ../flake/packages/highlight-js.nix { };
        };

        _forge-docs = pkgs.callPackage ../flake/packages/forge-docs.nix { };

        _forge-announcement = pkgs.writeShellApplication {
          name = "announce-projects";
          passthru = import ../maintainers/mk-announcement.nix { inherit forgeApps pkgs lib; };
          text = ''
            cat <<EOF
            To generate project announcement, use:

            \`\`\`
            nix run .#_forge-announcement.<APP_NAME>
            \`\`\`

            Available apps:
            ${lib.concatMapStringsSep "\n" (app: "- " + app.name) forgeApps}
            EOF
          '';
        };
      };
    };
}
