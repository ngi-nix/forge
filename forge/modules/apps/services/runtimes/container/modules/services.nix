{
  app,

  lib,
  ...
}:
lib.mapAttrs (
  serviceName: service:
  import ../../mkNimiImports.nix {
    inherit lib service;
  }
) app.services.components
