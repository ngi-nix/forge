{
  lib,
  ...
}:
{
  options = {
    nixosConfig = lib.mkOption {
      type = with lib.types; deferredModule;
      default = { };
      description = ''
        NixOS configuration options for the additional service.
        This configuration provides a runtime-independent definition that is used to build the full systemd environment for both VM and container runtimes.
      '';
    };

    ports = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Ports to expose for the extra component (e.g., [ "5432:5432" ]).
      '';
    };
  };
}
