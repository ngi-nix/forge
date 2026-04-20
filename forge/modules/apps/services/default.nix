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
              service is spawned.
            '';
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        }
      );
      default = { };
    };
  };
}
