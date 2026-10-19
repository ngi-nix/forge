{
  lib,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption "the resource" // {
      default = true;
      example = false;
    };

    nixosConfig = lib.mkOption {
      type = lib.types.deferredModule;
      default = { };
      description = ''
        Runtime independent configuration of the resource.

        See the list of available
        [NixOS options](https://search.nixos.org/options) .
      '';
      example = lib.literalExpression "{ services.postgresql.enable = true; }";
    };

    role = lib.mkOption {
      type = lib.types.enum [
        "backend"
        "frontend"
      ];
      default = "backend";
      description = ''
        Role of this resource relative to the service components.

        - `backend` (default): the components depend on this resource, so the
          resource starts before the components. Use this for services the
          components need at startup, such as a database or a message queue.

        - `frontend`: this resource depends on the components, so the components
          start before the resource. Use this for services that sit in front
          of the components, such as a reverse proxy, which needs the components
          to be running and resolvable in the container network DNS before it
          can start.
      '';
      example = lib.literalExpression ''"frontend"'';
    };

    ports = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "^[0-9]+:[0-9]+$");
      default = [ ];
      description = ''
        List of ports exposed by the resource.

        Format:
          _HOST_PORT:RESOURCE_PORT_
      '';
      example = lib.literalExpression ''[ "5432:5432" ]'';
      apply = self: lib.unique self;
    };
  };
}
