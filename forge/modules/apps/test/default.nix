{
  lib,
  specialArgs,
  ...
}:
{
  options = {
    programs = lib.mkOption {
      type = lib.types.submoduleWith {
        inherit specialArgs;
        modules = [ ./programs.nix ];
      };
      default = { };
      description = "Program test configuration.";
    };

    services = lib.mkOption {
      type = lib.types.submoduleWith {
        inherit specialArgs;
        modules = [ ./services ];
      };
      default = { };
      description = "Services test configuration.";
    };
  };
}
