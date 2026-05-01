{
  specialArgs,

  lib,
  ...
}:
{
  options = {
    components = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          inherit specialArgs;
          modules = [ ./component.nix ];
        }
      );
      default = { };
      description = "Portable service components.";
      example = lib.literalExpression ''
        {
          service1 = {
            command = pkgs.mypkgs.service1;
          };
          service2 = {
            command = pkgs.mypkgs.service2;
          };
        }
      '';
      # map user-config to a format which can be used by modular services
      apply =
        self:
        lib.mapAttrs (
          _: service:
          service
          // {
            result = {
              process.argv =
                let
                  command = if lib.isDerivation service.command then lib.getExe service.command else service.command;
                in
                [ command ] ++ service.argv;
              configData = service.configData;
              preStart = service.preStart;
              readyCheck = service.readyCheck;
              type = service.type;
            };
          }
        ) self;
    };

    runtimes = lib.mkOption {
      type = lib.types.submoduleWith {
        inherit specialArgs;
        modules = [ ./runtimes ];
      };
      default = { };
      description = "Portable services runtimes.";
    };

    ordering = lib.mkOption {
      description = ''
        Service startup ordering constraints.

        Each attribute names a service and declares which other services
        it must wait for before starting. Services without ordering
        constraints (or not mentioned here) start immediately.

        This only controls startup order inside a single nimi instance.
        It applies equally to containers, NixOS, Home Manager, and
        local development runs.
      '';
      example = lib.literalExpression ''
        {
          backend.after  = [ "database" ];
          frontend.after = [ "database" "backend" ];
        }
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.after = lib.mkOption {
            description = ''
              List of service names that must have started before this
              service is spawned (soft dependency, failure is okay).
            '';
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          options.afterReady = lib.mkOption {
            description = ''
              List of service names that must be ready before this
              service is spawned. Each target must declare a
              readiness check.
            '';
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          options.before = lib.mkOption {
            description = ''
              List of service names that must start after this service.
              Inverse of `after`: adds an implicit `after` on the target.
            '';
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          options.wants = lib.mkOption {
            description = ''
              List of soft dependencies: services that should be started,
              but failure is acceptable (matching systemd `Wants=`).
            '';
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          options.requires = lib.mkOption {
            description = ''
              List of hard dependencies: services that must start successfully
              before this service. If a required service fails, this service
              will not start (matching systemd `Requires=`).
            '';
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          # options.afterReady = lib.mkOption {
          #   description = ''
          #     List of service names that must be ready before this
          #     service is spawned. Each target must declare a
          #     readiness check.
          #   '';
          #   type = lib.types.listOf lib.types.str;
          #   default = [ ];
          # };
          # options.requires = lib.mkOption {
          #   description = ''
          #     Hard dependencies. If any required dependency fails, this
          #     service is stopped immediately.
          #   '';
          #   type = lib.types.listOf lib.types.str;
          #   default = [ ];
          # };
          # options.wants = lib.mkOption {
          #   description = ''
          #     Soft dependencies. If a wanted dependency fails, this service
          #     continues running. The failure is logged but not acted upon.
          #   '';
          #   type = lib.types.listOf lib.types.str;
          #   default = [ ];
          # };
          # options.bindsTo = lib.mkOption {
          #   description = ''
          #     Lifecycle-coupled dependencies. If a bound dependency stops
          #     or fails, this service is stopped. If it restarts and becomes
          #     ready, this service is also restarted.
          #   '';
          #   type = lib.types.listOf lib.types.str;
          #   default = [ ];
          # };
          # options.partOf = lib.mkOption {
          #   description = ''
          #     Stop-propagation dependencies. If the target service is
          #     stopped, this service is also stopped. Does not react to
          #     failures, only to explicit stops.
          #   '';
          #   type = lib.types.listOf lib.types.str;
          #   default = [ ];
          # };
        }
      );
      default = { };
    };
  };
}
