{
  config,
  lib,
  extendModules,

  inputs,
  nimi,
  pkgs,
  system,
  ...
}:
{
  options = {
    # General configuration
    name = lib.mkOption {
      type = lib.types.str;
      default = "my-application";
    };
    description = lib.mkOption {
      type = lib.types.str;
      default = "";
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
    links = lib.mkOption {
      type = lib.types.submodule ./links.nix;
      default = { };
      description = "Links related to this project";
    };
    ngi = lib.mkOption {
      type = lib.types.submodule ./ngi;
      default = { };
      description = "NGI-specific options.";
    };

    # Portable services configuration
    # https://nixos.org/manual/nixos/unstable/#modular-services
    services = lib.mkOption {
      type = lib.types.submoduleWith {
        specialArgs = {
          inherit
            inputs
            system
            pkgs
            nimi
            ;
          app = config;
        };
        modules = [ ./services ];
      };
      default = { };
      description = "Portable services configuration.";
    };

    # Programs shell configuration
    programs = lib.mkOption {
      type = lib.types.submodule ./programs;
      default = { };
      description = "Programs shell configuration.";
    };

    # Test configuration
    test = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./test ];
        _module.args.app = config;
        _module.args.pkgs = pkgs;
      };
      default = { };
      description = "Test configuration.";
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
