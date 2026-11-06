{
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

        Each component must have `process.command` set.
      '';
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
