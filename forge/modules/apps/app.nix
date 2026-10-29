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
          pkgs = config.effectivePkgs;
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
          pkgs = config.effectivePkgs;
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
          pkgs = config.effectivePkgs;
        };
        modules = [ ./test ];
      };
      default = { };
      description = "Test configuration.";
    };

    nixpkgsPin = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            rev = lib.mkOption {
              type = lib.types.str;
              description = "Git commit revision from NixOS/nixpkgs.";
              example = "02c087f3fe673c9e317f206a627cb6b910336dbe";
            };
            narHash = lib.mkOption {
              type = lib.types.str;
              description = "NAR hash of the pinned Nixpkgs tree.";
              example = "sha256-IoNisKcGbUjdd45qCqywGMCYmZ5EnkxezvLII0FWwNA=";
            };
          };
        }
      );
      default = null;
      description = ''
        Pin this application to a specific Nixpkgs revision using `builtins.fetchTree`.
        Allows using a different or older Nixpkgs version without adding another Nixpkgs input
        to `flake.lock`.
      '';
      example = {
        rev = "fe13242281a67641c0102cdb1087f0ebe586c7df";
        narHash = "sha256-zp8ToDMnqZcu4o4IH9pdwXFXGp7yLm/M0dEnNWnyd7I=";
      };
    };

    effectivePkgs = lib.mkOption {
      type = lib.types.raw;
      internal = true;
      readOnly = true;
      default =
        if config.nixpkgsPin != null then
          import (builtins.fetchTree {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
            inherit (config.nixpkgsPin) rev narHash;
          }) { inherit (pkgs) system; }
        else
          pkgs;
      description = "Effective Nixpkgs package set for this application (pinned or default).";
    };

    broken = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether the application is marked as broken.

        Broken applications are filtered out from default flake packages and marked with
        a warning in the web UI.

        > [!TIP]
        > If the application is broken due to an underlying package regression, consider
        > pinning the package with `nixpkgsPin` in its recipe. If the application itself
        > cannot run, set `broken = true;` and specify `lastWorkingVersion`.
      '';
      example = true;
    };

    lastWorkingVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Last known working Forge revision, git commit, or version for this application when broken.

        When set, the web UI displays instructions for running the application from its last
        known working version.
      '';
      example = "v0.1.0";
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
        resourceNames = lib.attrNames config.services.resources;
        # Components and resources share the same namespace (container names,
        # volumes, images and hostnames), their names must not clash.
        clashingNames = lib.intersectLists resourceNames componentNames;

        containerRuntime = config.services.runtimes.container;
        unknownContainerComponents = lib.subtractLists componentNames (
          lib.attrNames containerRuntime.components
        );
        unknownContainerResources = lib.subtractLists resourceNames (
          lib.attrNames containerRuntime.resources
        );

        programRuntime = config.programs.runtimes.program;
        mainPackage = config.programs.mainPackage;
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
          condition = clashingNames == [ ];
          message = ''
            App '${config.name}': services.resources names clash with services.components names: ${prettyPrint clashingNames}.
            Resources and components must have unique names.
          '';
        }
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
      ];
  };
}
