{
  config,
  lib,
  name,
  specialArgs,
  pkgs,
  ...
}:
{
  imports = [ ../recipe-metadata.nix ];
  config._recipeType = "apps";
  options = {
    name = lib.mkOption {
      default = name;
      type = lib.types.strMatching "^(‹name›|[a-zA-Z0-9-]+)$";
      description = "Application name. Only letters, numbers and hyphens are allowed.";
      example = "my-hello";
      readOnly = true;
      internal = true;
    };
    outputName = lib.mkOption {
      # The apps. prefix namespaces applications
      # when they're inserted into `allSystems.${system}.packages`.
      default = "apps.${config.name}";
      type = lib.types.str;
      description = "Package name to access the application, as in `nix run .#apps.my-hello`.";
      example = "apps.my-hello";
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
    maintainers = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = ''
        A list of the maintainers of this application.

        Maintainers needs to be either a Nixpkgs maintainer or a NGI Forge
        maintainer defined in `maintainers/maintainer-list.nix` file.
      '';
      example = lib.literalExpression "with lib.maintainers; [ ngi-nix ]";
    };
    scope = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "The scope for the application to allow the forge to categorise it.";
      example = lib.literalExpression ''[ "ocamlApps" "coolOcamlApps" ] # Scopes as apps.ocamlApps.coolOcamlApps.appName'';
      internal = true;
    };
    data = lib.mkOption {
      description = ''
        Data to be re-used in an application.

        Each entry can either be a path to an existing file, or a literal
        string, which are both normalized into a `{ name, content, path }`
        attribute set.

        For strings, `path` automatically resolves to a file in the Nix store containing the string content.
      '';
      default = { };
      example = lib.literalExpression ''
        {
          configFile = ./app.conf;
          greetingMessage = "hello world";
          testFile = {
            name = "my-test-file.txt";
            path = ./test/file.txt;
          };
        }
      '';
      type =
        let
          atomType = lib.types.either lib.types.path lib.types.str;

          toDataItem =
            value:
            if lib.isString value then
              {
                content = value;
              }
            else if lib.isPath value then
              {
                name = lib.baseNameOf value;
                path = value;
              }
            else
              # custom attribute set
              value;

          dataItemType = lib.types.coercedTo atomType toDataItem (
            lib.types.submoduleWith {
              modules = [ ./data-item.nix ];
              specialArgs = { inherit pkgs; };
            }
          );
        in
        lib.types.lazyAttrsOf dataItemType;
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

    broken = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the app is broken.";
    };

    packages = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.package);
      internal = true;
      readOnly = true;
      description = "Set of lists of all app packages.";
      example = lib.literalExpression ''
        {
          programs = config.programs.packages;
          nixos = config.services.runtimes.nixos.packages;
        }
      '';
    };

    packagesList = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      internal = true;
      readOnly = true;
      default = lib.flatten (lib.attrValues config.packages);
      description = "List of all app packages.";
    };
  };
  config = {
    packages =
      let
        # Returns a list of packages from each attribute path
        collectPackages =
          attrs: attrPath:
          lib.pipe attrs [
            (lib.mapAttrsToList (_: lib.attrByPath attrPath [ ]))
            (lib.flatten)
          ];
      in
      {
        programs = config.programs.packages;
        components = collectPackages config.services.components [
          "process"
          "packages"
        ];
        containerComponents = collectPackages config.services.runtimes.container.components [
          "packages"
        ];
        nixos = config.services.runtimes.nixos.packages;
        test = config.test.programs.packages ++ config.test.services.packages;
      };
  };
}
