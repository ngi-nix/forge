{
  lib,
  forge-inputs,
  config,
  system,
  app,
  ...
}@args:
let
  # Port mappings of all application services and resources, in "host:guest" notation.
  portMappings =
    let
      servicePorts = lib.concatMap (service: service.process.ports) (
        lib.attrValues app.services.components
      );
      resourcePorts = lib.pipe app.services.resources [
        (lib.mapAttrsToList (name: value: value.ports))
        (lib.flatten)
      ];
    in
    map (
      portRange:
      let
        portSplit = lib.splitString ":" portRange;
      in
      {
        host = lib.toInt (lib.elemAt portSplit 0);
        guest = lib.toInt (lib.elemAt portSplit 1);
      }
    ) (servicePorts ++ resourcePorts);

  moduleArgs = args // {
    inherit portMappings;
  };
in
{
  options = {
    enable = lib.mkEnableOption "NixOS runtime";

    setup = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Script to run once at system startup.
        Use this option for one-off system preparation steps.
      '';
      example = ''
        # bash
        echo "Creating directory structure ..."
        mkdir --parents /var/lib/myservice/config /var/lib/myservice/db
      '';
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        List of packages available in the NixOS system.

        Use this option to add packages required by setup script.

        This is a convenience option equivalent to setting
        `nixosConfig.environment.systemPackages`.
      '';
      example = lib.literalExpression "[ pkgs.btop ]";
    };

    nixosConfig = lib.mkOption {
      type = with lib.types; deferredModule;
      default = { };
      description = ''
        NixOS runtime specific configuration.

        See the list of available
        [NixOS options](https://search.nixos.org/options) .
      '';
      example = lib.literalExpression ''
        {
          services.postgresql.authentication = '''
            local all all trust
          ''';
        }
      '';
    };

    vm = {
      cores = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of CPU cores available to VM.";
        example = 8;
      };
      diskSize = lib.mkOption {
        type = lib.types.int;
        default = 1024 * 4;
        description = "VM disk size in MiB.";
        example = 1024 * 10;
      };
      memorySize = lib.mkOption {
        type = lib.types.int;
        default = 1024 * 2;
        description = "VM memory size in MiB.";
        example = 1024 * 4;
      };
    };

    imageVariants = lib.mkOption {
      internal = true;
      readOnly = true;
      type = with lib.types; listOf str;
      default = lib.attrNames config.result.images;
      description = ''
        Image variants supported by `nixos-rebuild build-image`.
        The images are available as `apps.''${app}.images.''${variant}`.
      '';
    };

    result = {
      modules = lib.mkOption {
        internal = true;
        readOnly = true;
        type = lib.types.attrsOf lib.types.anything;
        description = "NixOS modules for the application's services and extra configuration.";
      };

      eval = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "NixOS system evaluation.";
      };

      build = lib.mkOption {
        internal = true;
        readOnly = true;
        type = lib.types.package;
        default = config.result.eval.config.system.build.vm;
        description = "NixOS Virtual Machine.";
      };

      imageEval = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "NixOS system evaluation for disk images, without the virtual machine configuration.";
      };

      images = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf package;
        default = config.result.imageEval.config.system.build.images;
        description = "NixOS disk images, as built by `nixos-rebuild build-image`.";
      };

      nixosModule = lib.mkOption {
        internal = true;
        readOnly = true;
        type = lib.types.deferredModule;
        description = "Final application NixOS module exposed as packages.\${system}.apps.\${app}.nixosModules.default.";
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

  config = {
    result.modules = {
      general = import ./modules/general.nix moduleArgs;
      setup = import ./modules/setup.nix moduleArgs;
      nimi = import ./modules/nimi.nix moduleArgs;
      virt = import ./modules/virt.nix moduleArgs;
      nixosConfig = config.nixosConfig;
      packages = {
        environment.systemPackages = config.packages;
      };
      nixosComponents = {
        imports = lib.mapAttrsToList (name: value: value.nixosConfig) app.services.resources;

        networking.extraHosts =
          let
            componentNames = lib.attrNames app.services.components;
            resourceNames = lib.concatMap (c: lib.attrNames c.resources) (
              lib.attrValues app.services.components
            );
          in
          lib.concatMapStringsSep "\n" (name: "127.0.0.1 ${name}") (
            lib.unique (componentNames ++ resourceNames)
          );
      };
    };

    result.nixosModule = {
      imports = [
        config.result.modules.setup
        config.result.modules.nimi
        config.result.modules.packages
        config.result.modules.nixosConfig
        config.result.modules.nixosComponents
      ];
    };

    result.eval = forge-inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = lib.attrValues config.result.modules;
    };

    result.imageEval = forge-inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        config.result.nixosModule
        (import ./modules/image.nix moduleArgs)
      ];
    };
  };
}
