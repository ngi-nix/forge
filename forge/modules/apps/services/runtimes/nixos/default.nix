{
  lib,
  inputs,

  app,
  config,
  system,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption "NixOS/VM output";

    setup = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Script to run once at startup.";
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
        type = lib.types.listOf lib.types.anything;
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
    result.modules = [
      # nimi NixOS module — runs services via nimi process manager
      inputs.nimi.nixosModules.default
      {
        nimi = lib.mapAttrs (serviceName: service: {
          settings.binName = "${serviceName}-service";
          services.${serviceName} = {
            imports = [
              service.result
              {
                options.nimi = lib.mkOption {
                  type = with lib.types; deferredModule;
                  default = { };
                  description = ''
                    Let the modular service know that it's evaluated for nimi,
                    by testing `options ? nimi`.
                  '';
                };
              }
            ];
          };
        }) app.services.components;

        environment.variables =
          let
            /*
              Convert a list of environment variables to an attribute set.

              Example:
                [ "K=V" ] -> { K = "V"; }
            */
            envListToAttrs =
              list:
              lib.pipe list [
                (map (envPair: lib.splitString "=" envPair))
                (map (envPairSplit: {
                  name = lib.head envPairSplit;
                  value = lib.concatStringsSep "=" (lib.tail envPairSplit);
                }))
                (lib.listToAttrs)
              ];
          in
          lib.concatMapAttrs (_: value: envListToAttrs value.environment) app.services.components;
      }
      (lib.mkIf (config.setup != "") {
        systemd.services."${app.name}-setup" = {
          description = "Setup service for ${app.name}.";
          wantedBy = [ "multi-user.target" ];
          before = [ "multi-user.target" ];
          after = [ "network.target" ];
          script = config.setup;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };
      })
      config.extraConfig
    ];

    result.eval = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        (
          { modulesPath, ... }:
          {
            imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

            virtualisation = {
              graphics = false;

              inherit (config.vm)
                cores
                diskSize
                memorySize
                ;

              forwardPorts = map (
                portRange:
                if builtins.isString portRange then
                  let
                    portSplit = lib.splitString ":" portRange;
                  in
                  {
                    from = "host";
                    host.port = lib.toInt (lib.elemAt portSplit 0);
                    guest.port = lib.toInt (lib.elemAt portSplit 1);
                  }
                else
                  portRange
              ) config.vm.forwardPorts;
            };
          }
        )
        {
          users.users.root.password = "root";

          services = {
            openssh.settings.PermitRootLogin = lib.mkForce "yes";
            openssh.settings.PasswordAuthentication = lib.mkForce true;
            getty.autologinUser = "root";
          };

          networking = {
            hostName = app.name;
            useDHCP = lib.mkForce true;
            firewall.enable = lib.mkForce false;
          };

          system.stateVersion = "25.11";
        }
      ]
      ++ config.result.modules;
    };
  };
}
