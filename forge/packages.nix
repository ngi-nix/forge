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
              # Avoid building packages when generating options.json
              # by ensuring defaults and examples don't contain derivations.
              default = if opt ? default && lib.isDerivation opt.default then null else opt.default or null;
              example = if opt ? example && lib.isDerivation opt.example then null else opt.example or null;
            };
        };

      forgeOptions = forgeOptionsDoc forgeModules;

      # Collect app icons into a derivation
      appIcons = pkgs.runCommand "app-icons" { } ''
        mkdir -p $out
        ${lib.concatStringsSep "\n" (
          map (app: ''
            mkdir -p $out/${app.name}
            ${if app.icon or null != null then "cp ${app.icon} $out/${app.name}/icon.svg" else ""}
          '') config.forge.apps
        )}
      '';
    in
    {
      packages = {
        _forge-config = pkgs.writeTextFile {
          name = "forge-config.json";
          text = builtins.toJSON (
            config.forge
            // {
              packages = map (pkg: {
                inherit (pkg)
                  name
                  description
                  version
                  homePage
                  mainProgram
                  license
                  recipePath
                  ;
                source = {
                  inherit (pkg.source)
                    git
                    url
                    path
                    hash
                    patches
                    ;
                };
              }) config.forge.packages;
              apps = map (app: {
                inherit (app)
                  name
                  displayName
                  description
                  usage
                  icon
                  ngi
                  links
                  recipePath
                  ;
                programs = {
                  runtimes = {
                    inherit (app.programs.runtimes) shell;
                  };
                };
                services = {
                  runtimes = {
                    container = {
                      inherit (app.services.runtimes.container) enable;
                    };
                    nixos = {
                      inherit (app.services.runtimes.nixos) enable;
                    };
                  };
                };
              }) config.forge.apps;
            }
          );
        };

        _forge-options = pkgs.runCommand "options.json" { } ''
          cp ${forgeOptions.optionsJSON}/share/doc/nixos/options.json $out
        '';

        _forge-ui = pkgs.callPackage ../ui/package.nix {
          inherit (config.packages) _forge-config _forge-docs _forge-options;
          inherit appIcons;
          buildElmApplication = (inputs.elm2nix.lib.elm2nix pkgs).buildElmApplication;
        };

        _forge-docs = pkgs.callPackage ../flake/packages/forge-docs.nix { };
      };
    };
}
