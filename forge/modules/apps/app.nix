{
  config,
  lib,
  name,
  specialArgs,
  pkgs,
  ...
}:
{
  imports = [
    ../assertions-warnings.nix
    ../recipe-metadata.nix
  ];
  config._recipeType = "apps";
  options = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = specialArgs.enable;
      defaultText = lib.literalExpression "config.forge.enable";
      description = "Whether to publish the app in Forge repository in Flake output.";
    };
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
    longDescription = lib.mkOption {
      type = lib.types.str // {
        check = v: lib.isString v && lib.stringLength v <= 420;
        description = "string of 420 characters or fewer";
      };
      default = "";
      description = "Long application description. Maximum 420 characters.";
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
          valueType = lib.types.oneOf [
            lib.types.str
            lib.types.int
            lib.types.bool
            lib.types.float
          ];

          atomType = lib.types.oneOf [
            lib.types.path
            valueType
          ];

          toDataItem =
            value:
            if valueType.check value then
              {
                value = value;
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
              specialArgs = { inherit pkgs valueType; };
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

    broken = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the app is broken.";
    };

    packages = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.package);
      internal = true;
      readOnly = true;
      description = "Lists of packages used by application.";
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

  config = {
    packages =
      let
        # Collects packages found at `attrPaths` across every item of `attrs`.
        # Each path may point at either a single package or a list of
        # packages; non-package values (e.g. `process.command` set to a
        # bare executable name) are dropped.
        collectPackages =
          attrPaths: attrs:
          lib.pipe attrs [
            (lib.mapAttrsToList (_: item: map (attrPath: lib.attrByPath attrPath [ ] item) attrPaths))
            (lib.flatten)
            (lib.filter lib.isDerivation)
          ];
      in
      {
        programs = collectPackages [
          [ "mainPackage" ]
          [ "packages" ]
        ] { programs = config.programs; };
        services = collectPackages [
          [
            "process"
            "command"
          ]
          [
            "process"
            "packages"
          ]
        ] config.services.components;
      };

    assertions =
      let
        prettyPrint = lib.generators.toPretty { multiline = false; };

        components = config.services.components;
        componentNames = lib.attrNames components;
        resourceNames = lib.unique (
          lib.concatMap (component: lib.attrNames component.resources) (lib.attrValues components)
        );

        containerRuntime = config.services.runtimes.container;
        unknownContainerComponents = lib.subtractLists componentNames (
          lib.attrNames containerRuntime.components
        );
        unknownContainerResources = lib.subtractLists resourceNames (
          lib.attrNames containerRuntime.resources
        );

        programRuntime = config.programs.runtimes.program;
        mainPackage = config.programs.mainPackage;
        browserRuntime = config.programs.runtimes.browser;
      in
      lib.mapAttrsToList (
        componentName: component:
        let
          unknownDependsOn = lib.subtractLists componentNames component.dependsOn;
        in
        {
          condition = unknownDependsOn == [ ];
          message = ''
            App '${config.name}': services.components.${componentName}.dependsOn references unknown components: ${prettyPrint unknownDependsOn}.
            Available components: ${prettyPrint componentNames}.
          '';
        }
      ) components
      ++ [
        {
          condition = unknownContainerComponents == [ ];
          message = ''
            App '${config.name}': services.runtimes.container.components references unknown components: ${prettyPrint unknownContainerComponents}.
            Available components: ${prettyPrint componentNames}.
          '';
        }
        {
          condition = unknownContainerResources == [ ];
          message = ''
            App '${config.name}': services.runtimes.container.resources references unknown resources: ${prettyPrint unknownContainerResources}.
            Available resources: ${prettyPrint resourceNames}.
          '';
        }
        {
          condition = programRuntime.enable -> mainPackage != null;
          message = ''
            App '${config.name}': programs.runtimes.program.enable requires programs.mainPackage to be set.
          '';
        }
        {
          condition =
            (programRuntime.enable && mainPackage != null)
            -> lib.hasAttrByPath [ "meta" "mainProgram" ] mainPackage;
          message = ''
            App '${config.name}': programs.mainPackage is missing the meta.mainProgram attribute.
          '';
        }
        {
          condition =
            browserRuntime.enable -> (config.programs.packages != [ ] || browserRuntime.wasmPackage != null);
          message = ''
            App '${config.name}': programs.runtimes.browser.enable requires programs.packages or programs.runtimes.browser.wasmPackage to be set.
          '';
        }
        {
          condition =
            browserRuntime.wasmPackage != null
            -> lib.hasAttrByPath [ "meta" "mainProgram" ] browserRuntime.wasmPackage;
          message = ''
            App '${config.name}': programs.runtimes.browser.wasmPackage is missing the meta.mainProgram attribute.
          '';
        }
      ];
  };
}
