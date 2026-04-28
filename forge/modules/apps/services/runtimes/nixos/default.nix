{
  lib,
  inputs,

  app,
  config,
  system,
  ...
}@args:
{
  options = {
    enable = lib.mkEnableOption "NixOS/VM output";

    setup = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Script to run once at startup.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Packages to add to the NixOS system.

        This is a convenience option equivalent to setting
        `extraConfig.environment.systemPackages`.
      '';
      example = lib.literalExpression "[ pkgs.btop ]";
    };

    extraConfig = lib.mkOption {
      type = with lib.types; deferredModule;
      default = { };
      description = ''
        NixOS system configuration

        See: https://search.nixos.org/options
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
      forwardPorts = lib.mkOption {
        type = lib.types.listOf (lib.types.strMatching "^[0-9]*:[0-9]*$");
        default = [ ];
        description = ''
          List of ports to forward from host system to VM.

          Format: HOST_PORT:VM_PORT
        '';
        example = lib.literalExpression ''
          [ "10022:22" "5432:5432" "8000:80" ]
        '';
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
      general = import ./modules/general.nix args;
      setup = import ./modules/setup.nix args;
      nimi = import ./modules/nimi.nix args;
      virt = import ./modules/virt.nix args;
      extraConfig = config.extraConfig;
      packages = {
        environment.systemPackages = config.packages;
      };
    };

    result.eval = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = lib.attrValues config.result.modules;
    };
  };
}
