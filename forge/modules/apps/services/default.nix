{
  options,
  config,
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
      # map user-config to a format which can be used by modular services
      apply =
        self:
        lib.mapAttrs (
          _: service:

          let
            knownComponents = lib.attrNames config.components;
            invalidAfterDeps = lib.filter (dep: !lib.elem dep knownComponents) service.after;
            optionPath = lib.showOption (options.components.loc ++ [ service.name ]);

            prettyPrint = lib.generators.toPretty { };

            checks.after = {
              cond = invalidAfterDeps != [ ];
              msg = ''
                `${optionPath}.after` references invalid services: ${prettyPrint invalidAfterDeps}
                Must be one of: ${prettyPrint knownComponents}
              '';
            };

            serviceCommand =
              if lib.isDerivation service.command then lib.getExe service.command else service.command;
          in

          assert (lib.any (c: lib.throwIf c.cond c.msg true) (lib.attrValues checks));

          service
          // {
            result = {
              process.argv = [ serviceCommand ] ++ service.argv;
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
