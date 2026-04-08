{
  specialArgs,

  lib,
  ...
}:
{
  options = {
    # Container configuration
    container = lib.mkOption {
      type = lib.types.submoduleWith {
        inherit specialArgs;
        modules = [ ./container ];
      };
      default = { };
      description = "Container configuration.";
    };

    # NixOS/VM configuration
    nixos = lib.mkOption {
      type = lib.types.submoduleWith {
        inherit specialArgs;
        modules = [ ./nixos ];
      };
      default = { };
      description = "NixOS system configuration.";
    };
  };
}
