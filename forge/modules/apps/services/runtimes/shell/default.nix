{
  lib,

  nimi,
  app,
  ...
}:
{

  options = {
    result = lib.mkOption {
      internal = true;
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Script that start service shell.";
    };
  };

  config = {
    result = nimi.mkNimiBin { config = app.services.runtimes.container.result.modules; };
  };
}
