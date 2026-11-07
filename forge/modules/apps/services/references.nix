# Upstream documentation of the configuration of a service process.
{ lib, ... }:
let
  link = import ../link-type.nix { inherit lib; };

  reference =
    description:
    lib.mkOption {
      type = lib.types.nullOr link;
      default = null;
      inherit description;
    };
in
{
  options.references = {
    commandLine = reference "Upstream reference of the command line options.";
    environment = reference "Upstream reference of the environment variables.";
    configFile = reference "Upstream reference of the format of the configuration files.";
  };
}
