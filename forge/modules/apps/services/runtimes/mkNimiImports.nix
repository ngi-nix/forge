{
  lib,
  service,
}:
{
  imports = [
    service.result
    {
      options.nimi = lib.mkOption {
        type = with lib.types; deferredModule;
        default = { };
        description = ''
          Let the modular service know that it's evaluated for nimi,
          by testing `options ? nimi`.
        '';
      };
    }
  ];
}
