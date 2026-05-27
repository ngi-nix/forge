{
  lib,
  specialArgs,
  ...
}:
{
  options = {
    grants = lib.mkOption {
      type = lib.types.submoduleWith {
        inherit specialArgs;
        modules = [ ./grants.nix ];
      };
      default = { };
      description = "NGI grants supporting this project.";
    };
  };
}
