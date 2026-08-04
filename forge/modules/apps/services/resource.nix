{
  lib,
  ...
}:
{
  options.nixosConfig = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
    description = ''
      Runtime independent configuration of the resource.

      See the list of available
      [NixOS options](https://search.nixos.org/options) .
    '';
    example = lib.literalExpression "{ services.postgresql.enable = true; }";
  };
  options.role = lib.mkOption {
    type = lib.types.enum [
      "backend"
      "frontend"
    ];
    default = "backend";
    description = ''
      Role of this resource relative to the component that declares it.

      - `backend` (default): the component depends on this resource, so the
        resource starts before the component. Use this for services the
        component needs at startup, such as a database or a message queue.

      - `frontend`: this resource depends on the component, so the component
        starts before the resource. Use this for services that sit in front
        of the component, such as a reverse proxy, which needs the component
        to be running and resolvable in the container network DNS before it
        can start.
    '';
    example = lib.literalExpression ''"frontend"'';
  };
  options.ports = lib.mkOption {
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
}
