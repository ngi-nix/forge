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
            command = systemConfig.packages.service1;
          };
          service2 = {
            command = systemConfig.packages.service2;
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
  };
}
