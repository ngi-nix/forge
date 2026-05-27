{
  config,
  lib,
  name,
  specialArgs,
  ...
}:
{
  options = {
    # General configuration
    name = lib.mkOption {
      default = name;
      type = lib.types.strMatching "^(‹name›|[a-zA-Z0-9-]+)$";
      description = "Application name. Only letters, numbers and hyphens are allowed.";
      example = "my-hello";
      readOnly = true;
      internal = true;
    };
    pname = lib.mkOption {
      # The -app suffix acts as a namespace for applications
      # when they're inserted into `allSystems.${system}.packages`.
      default = "${config.name}-app";
      type = lib.types.str;
      description = "Package name to access the application, as in `nix run .#my-hello-app`.";
      example = "my-hello-app";
      readOnly = true;
      internal = true;
    };
    displayName = lib.mkOption {
      type = lib.types.str;
      default = config.name;
      description = "Human readable application name. Defaults to `name` if not set.";
      example = "My Hello Application";
    };
    description = lib.mkOption {
      type = lib.types.strMatching "^$|^.{1,119}\\.$";
      default = "";
      description = "Short application description. Maximum 120 characters.";
      example = "A fast and secure web server for self-hosted applications.";
    };
    usage = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Application usage description in markdown format.";
      example = ''
        Launch the application in your browser at `http://localhost:8080`.

        ## Default credentials

        - Username: `admin`
        - Password: `admin`
      '';
    };
    icon = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to application icon in SVG format. If not specified, a default icon
        will be used.
      '';
      example = lib.literalExpression "./icon.svg";
    };
    links = lib.mkOption {
      type = lib.types.submoduleWith {
        specialArgs = specialArgs // {
          app = config;
        };
        modules = [ ./links.nix ];
      };
      default = { };
      description = "Links related to this project.";
    };
    ngi = lib.mkOption {
      type = lib.types.submoduleWith {
        specialArgs = specialArgs // {
          app = config;
        };
        modules = [ ./ngi ];
      };
      default = { };
      description = "NGI specific options.";
    };

    # Portable services configuration
    # https://nixos.org/manual/nixos/unstable/#modular-services
    services = lib.mkOption {
      type = lib.types.submoduleWith {
        specialArgs = specialArgs // {
          app = config;
        };
        modules = [ ./services ];
      };
      default = { };
      description = "Services configuration.";
    };

    # Programs configuration
    programs = lib.mkOption {
      type = lib.types.submoduleWith {
        specialArgs = specialArgs // {
          app = config;
        };
        modules = [ ./programs ];
      };
      default = { };
      description = "Programs configuration.";
    };

    # Test configuration
    test = lib.mkOption {
      type = lib.types.submoduleWith {
        specialArgs = specialArgs // {
          app = config;
        };
        modules = [ ./test ];
      };
      default = { };
      description = "Test configuration.";
    };

    # Warning(correctness): this currently remains empty,
    # as it's currently ill-defined: a recipe can be a merge of multiple files.
    recipePath = lib.mkOption {
      type = lib.types.str;
      default = "";
      internal = true;
      description = "Path to the recipe.nix file relative to the flake root. Set automatically by the recipe loader.";
    };

    result = {
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
