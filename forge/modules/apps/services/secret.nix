# A secret of a service component.
{
  name,
  config,
  lib,
  pkgs,
  # Name of the service component of the secret.
  componentName,
  ...
}:
{
  options = {
    # The name of a systemd credential and of a file in the
    # `$CREDENTIALS_DIRECTORY` directory.
    name = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9_.-]+";
      default = name;
      description = "Name of the secret. Only letters, digits, `_`, `.` and `-` are allowed.";
      readOnly = true;
      internal = true;
    };

    value = lib.mkOption {
      type = lib.types.str;
      description = ''
        Insecure default value of the secret.

        The value is stored in the Nix store. It is used in the NixOS VM, in containers
        and in tests. Replace it in NixOS deployments.
      '';
      example = "insecure-default-key-change-in-production";
    };

    description = lib.mkOption {
      type = lib.types.str;
      description = "Description of the secret.";
      example = "Application admin password.";
    };

    environment = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "[A-Za-z_][A-Za-z0-9_]*");
      default = null;
      description = ''
        Name of the environment variable which gets the value of the secret.

        Set to `null` to only provide the secret as a file.
      '';
      example = "SECRET_KEY";
    };

    defaultFile = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      default = pkgs.writeText "${componentName}-${config.name}" config.value;
      defaultText = lib.literalMD "Nix store file with the `value`";
      description = "Nix store file with the default value of the secret.";
    };

    composeName = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = "${componentName}-${config.name}";
      description = "Name of the secret in the compose file of the container runtime.";
    };
  };
}
