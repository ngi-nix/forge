# ToDo(correctness): those arguments should eventually be removed or moved to `appArgs`.
{
  extendModules,
  inputs,
  ...
}:
{
  flake.modules.apps.default.imports = [
    (
      {
        lib,
        name,
        pkgs,
        system,
        specialArgs,
        ...
      }@appArgs:
      {
        options = {
          # General configuration
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
            readOnly = true;
            description = "Application name.";
            example = "hello";
          };
          displayName = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Human readable application name. Defaults to `name` if not set.";
            example = "Hello";
          };
          description = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Description of the application.";
          };
          usage = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Application usage description in markdown format.";
          };
          icon = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to application icon (SVG file). If not specified, a default icon will be used.";
            example = lib.literalExpression "./icon.svg";
          };
          # ToDo(modularity): make it a toplevel module recording itself to `flake.modules.apps.default.imports`
          links = lib.mkOption {
            type = lib.types.submodule ./_links.nix;
            default = { };
            description = "Links related to this project";
          };
          # ToDo(modularity): make it a toplevel module recording itself to `flake.modules.apps.default.imports`
          ngi = lib.mkOption {
            type = lib.types.submodule ./_ngi;
            default = { };
            description = "NGI-specific options.";
          };

          # ToDo(modularity): make it a toplevel module recording itself to `flake.modules.apps.default.imports`
          # Portable services configuration
          # https://nixos.org/manual/nixos/unstable/#modular-services
          services = lib.mkOption {
            type = lib.types.submoduleWith {
              specialArgs = specialArgs // {
                inherit
                  inputs
                  system
                  pkgs
                  ;
                app = appArgs.config;
              };
              modules = [ ./_services ];
            };
            default = { };
            description = "Portable services configuration.";
          };

          # ToDo(modularity): make it a toplevel module recording itself to `flake.modules.apps.default.imports`
          # Programs configuration
          programs = lib.mkOption {
            type = lib.types.submodule ./_programs;
            default = { };
            description = "Programs configuration.";
          };

          # ToDo(modularity): make it a toplevel module recording itself to `flake.modules.apps.default.imports`
          # Test configuration
          test = lib.mkOption {
            type = lib.types.submodule {
              imports = [ ./_test ];
              _module.args.app = appArgs.config;
              _module.args.pkgs = pkgs;
            };
            default = { };
            description = "Test configuration.";
          };

          # Error(portability): this is assumes all recipes are in this repository.
          # This should be replaced by `recipeUrl`.
          recipePath = lib.mkOption {
            type = lib.types.str;
            default = "";
            internal = true;
            description = "Path to the recipe.nix file relative to the flake root. Set automatically by the recipe loader.";
          };

          result = {
            extend = lib.mkOption {
              internal = true;
              readOnly = true;
              default = module: (extendModules { modules = [ module ]; }).config;
            };

            # HACK:
            # Prevent toJSON from attempting to convert the `eval` option,
            # which won't work because it's a whole NixOS evaluation.
            __toString = lib.mkOption {
              internal = true;
              readOnly = true;
              type = with lib.types; functionTo str;
              default = self: "nixos-vm-config";
            };
          };
        };
      }
    )
  ];
}
