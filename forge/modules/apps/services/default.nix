{
  options,
  config,
  specialArgs,

  forge-lib,
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
      description = ''
        Services components.

        Each component must have `process.command` set.
      '';
      apply =
        self:
        lib.mapAttrs (
          _: service:
          forge-lib.checkKnownNames {
            optionPath = lib.showOption (options.components.loc ++ [ service.name ]) + ".dependsOn";
            names = service.dependsOn;
            knownNames = lib.attrNames config.components;
          } service
          // {
            result = {
              process.argv =
                let
                  serviceCommand =
                    if lib.isDerivation service.process.command then
                      lib.getExe service.process.command
                    else
                      service.process.command;
                in
                [ serviceCommand ] ++ service.process.argv;
              configData = service.process.configData;
              preStart = service.process.preStart;
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

    resources = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ./resource.nix);
      default = { };
      description = ''
        Resource configuration.

        Resources are shared by all service components.
      '';
      example = lib.literalExpression ''
        {
          database.nixosConfig = { services.postgresql.enable = true; };
          cache.nixosConfig = { services.redis.servers.default.enable = true; };
        }
      '';
      # Components and resources share the same namespace (container names,
      # volumes, images and hostnames), their names must not clash.
      apply =
        self:
        let
          clashingNames = lib.intersectLists (lib.attrNames self) (lib.attrNames config.components);
          prettyPrint = lib.generators.toPretty { };
        in
        lib.throwIf (clashingNames != [ ]) ''
          `${lib.showOption options.resources.loc}` names clash with `${lib.showOption options.components.loc}` names: ${prettyPrint clashingNames}
          Resources and components must have unique names.
        '' self;
    };

    result.enabledResources = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.raw;
      default = lib.filterAttrs (_: resource: resource.enable) config.resources;
      description = "Enabled resources, by name.";
    };
  };
}
