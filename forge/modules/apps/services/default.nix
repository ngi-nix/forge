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
      description = ''
        Services components.

        Each component must have `process.command` set and can optionally
        declare one or more `resources` providing NixOS configuration.
      '';
      apply =
        self:
        lib.mapAttrs (
          _: service:
          let
            knownComponents = lib.attrNames config.components;
            invalidDependsOn = lib.filter (dep: !lib.elem dep knownComponents) service.dependsOn;
            optionPath = lib.showOption (options.components.loc ++ [ service.name ]);

            prettyPrint = lib.generators.toPretty { };

            checks.dependsOn = {
              cond = invalidDependsOn != [ ];
              msg = ''
                `${optionPath}.dependsOn` references invalid services: ${prettyPrint invalidDependsOn}
                Must be one of: ${prettyPrint knownComponents}
              '';
            };

          in

          assert (lib.any (c: lib.throwIf c.cond c.msg true) (lib.attrValues checks));

          service
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
      internal = true;
      type = lib.types.attrsOf (lib.types.submodule ./resource.nix);
      default = { };
      description = "Resource configuration";
      example = lib.literalExpression ''
        {
          database.nixosConfig = { services.postgresql.enable = true; };
          cache.nixosConfig = { services.redis.servers.default.enable = true; };
        }
      '';
    };
  };

  config.resources =
    let
      componentResources = lib.pipe config.components [
        (lib.attrValues)
        (lib.catAttrs "resources")
      ];

      runtimeResources = [ config.runtimes.container.resources ];
    in
    lib.mkMerge (runtimeResources ++ componentResources);
}
