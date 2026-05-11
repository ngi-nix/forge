{
  app,
  lib,
  ...
}:
({ lib, ... }: {
  services = lib.mapAttrs (_: service: {
    service = {
      command = service.result.process.argv;
      environment = lib.mapAttrsToList (n: v: "${n}=${v}") service.environment;
    };
  }) app.services.components;
})
