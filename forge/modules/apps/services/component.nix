{
  name,
  forge-inputs,
  pkgs,

  lib,
  ...
}:
let
  componentName = name;
in
{
  imports = [ ./endpoints.nix ];

  options = {
    name = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.str;
      default = name;
      description = "Name of service component.";
    };

    process = lib.mkOption {
      type = lib.types.submoduleWith {
        modules = [
          (lib.modules.importApply (forge-inputs.nixpkgs + "/lib/services/config-data.nix") {
            inherit pkgs;
          })
          {
            options = {
              command = lib.mkOption {
                type = lib.types.either lib.types.package lib.types.str;
                description = ''
                  Main command used to launch the service.

                  Can be a package (e.g. `pkgs.hello`) or an explicit binary path.
                '';
                example = lib.literalExpression ''"''${pkgs.hello}/bin/hello"'';
              };

              argv = lib.mkOption {
                type = lib.types.listOf lib.types.singleLineStr;
                default = [ ];
                description = "List of arguments that will be passed to the main program.";
                example = [
                  "--config"
                  "service.toml"
                ];
              };

              environment = lib.mkOption {
                type = lib.types.attrsOf (lib.types.coercedTo lib.types.int toString lib.types.str);
                default = { };
                description = ''
                  Environment variables passed to the service.

                  Integers are converted to strings, for example
                  `PORT = app.parameters.port`.
                '';
                example = lib.literalExpression ''
                  {
                    DEBUG = "1";
                    LOG_LEVEL = "info";
                    PORT = 8080;
                  }
                '';
              };

              preStart = lib.mkOption {
                description = ''
                  Script to run before each start of this service.

                  Runs before every start attempt, including restarts.
                  If the script exits with a non-zero status, the service
                  is considered failed and the restart policy applies.

                  Set to `null` to disable.
                '';
                type = lib.types.nullOr lib.types.str;
                default = null;
                apply = self: if self != null then pkgs.writeShellScript "${name}-pre-start" self else null;
                example = ''
                  # bash
                  echo "Running DB migration ..."
                  program-manage makemigrations && program-manage migrate
                '';
              };

              user = lib.mkOption {
                type = lib.types.enum [
                  "root"
                  "prefer-dynamic"
                  "non-privileged"
                ];
                default = "prefer-dynamic";
                description = ''
                  User account under which the service runs.

                  - `root`: service runs as root. A non-privileged user and group named
                    after the service are also created for services that start as root
                    and then drop privileges.

                  - `prefer-dynamic`: on NixOS runtime , uses `DynamicUser` - no physical
                    user or group account is created. On container runtime, uses a
                    non-privileged user named after the service.

                  - `non-privileged`: service always runs as a non-privileged user named
                    after the service.
                '';
              };

              stateDir = lib.mkOption {
                type = lib.types.strMatching "^/var/lib/[^/].*$";
                default = "/var/lib/${name}";
                description = ''
                  Path to the service state directory.

                  Must be located in `/var/lib/`.
                '';
                example = "/var/lib/myservice";
              };

              packages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = ''
                  Additional packages available for the service.
                '';
                example = lib.literalExpression "[ pkgs.rsync pkgs.jq ]";
              };
            };
          }
        ];
      };
      description = "Process configuration.";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }:
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
        )
      );
      default = { };
      description = ''
        Secrets of the service.

        Each secret is a file in the `$CREDENTIALS_DIRECTORY` directory, named after the secret.
        On NixOS runtime, the secret is loaded with systemd's `LoadCredential`.
        On container runtime, the secret is mounted to `/run/secrets`.

        The NixOS VM, containers and tests use the insecure default `value`.
        NixOS deployments replace it with the `forge.apps.<app>.secrets.<component>.<secret>`
        option of the application NixOS module.

        Names of secrets can contain only letters, digits, `_`, `.` and `-`.
      '';
      example = lib.literalExpression ''
        {
          secret-key = {
            value = "insecure-default-key-change-in-production";
            description = "Secret key for signing session cookies.";
            environment = "SECRET_KEY";
          };
        }
      '';
    };

    healthcheck = lib.mkOption {
      type = lib.types.submodule ./healthcheck.nix;
      default = { };
      description = "Health check configuration.";
    };

    dependsOn = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of service components that need to be started before this one.
      '';
      example = lib.literalExpression ''
        [ "foobar-server" ]
      '';
    };
  };
}
