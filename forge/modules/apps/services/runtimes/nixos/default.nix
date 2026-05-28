{
  lib,
  forge-inputs,
  config,
  system,
  app,
  ...
}@args:
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
        NixOS system configuration.

        See the list of available
        [NixOS options](https://search.nixos.org/options) .
      '';
      example = lib.literalExpression ''
        {
          services.postgresql.enable = true;
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

    extraComponents = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          inherit (args) specialArgs;
          modules = [
            {
              options = {
                nixosConfig = lib.mkOption {
                  type = with lib.types; deferredModule;
                  default = { };
                  description = "NixOS runtime-specific NixOS system configuration overrides.";
                };
              };
            }
          ];
        }
      );
      default = { };
      description = ''
        NixOS runtime-specific overrides for extra components.
        Use this to configure settings that are only applicable when running the component natively on NixOS (e.g., DNS mapping for localhost via networking.extraHosts).
      '';
      apply =
        self:
        let
          knownComponents = lib.attrNames app.services.extraComponents;
          unknownComponents = lib.subtractLists knownComponents (lib.attrNames self);
        in
        lib.throwIf (unknownComponents != [ ])
          "services.runtimes.nixos.extraComponents: unknown extraComponent(s): ${lib.concatStringsSep ", " unknownComponents}. Must be one of: ${lib.concatStringsSep ", " knownComponents}"
          self;
    };
  };

  config = {
    result.modules = {
      general = import ./modules/general.nix args;
      setup = import ./modules/setup.nix args;
      nimi = import ./modules/nimi.nix args;
      virt = import ./modules/virt.nix args;
      nixosConfig = config.nixosConfig;
      packages = {
        environment.systemPackages = config.packages;
      };
      extraComponents = {
        imports =
          (lib.mapAttrsToList (name: value: value.nixosConfig) app.services.extraComponents)
          ++ (lib.mapAttrsToList (name: value: value.nixosConfig) config.extraComponents);
      };
    };

    result.nixosModule = {
      imports = [
        config.result.modules.setup
        config.result.modules.nimi
        config.result.modules.packages
        config.result.modules.nixosConfig
        config.result.modules.extraComponents
      ];
    };

    result.eval = forge-inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = lib.attrValues config.result.modules;
    };
  };
}
