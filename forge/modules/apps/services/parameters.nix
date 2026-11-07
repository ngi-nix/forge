# Run-time parameters of a service process.
#
# A parameter is an environment variable that the user of a built service can
# change. `mkServiceRunner.nix` gives the value to the service as a flag if
# `flag` is set. Thus, a service that does not read environment variables can
# use the same interface.
{ config, lib, ... }:
let
  parameterType = lib.types.submodule (
    { config, name, ... }:
    {
      options = {
        description = lib.mkOption {
          type = lib.types.singleLineStr;
          description = "Description of the parameter for the user of the service.";
        };

        type = lib.mkOption {
          type = lib.types.enum [
            "string"
            "integer"
            "boolean"
          ];
          default = "string";
          description = "JSON Schema type of the parameter.";
        };

        default = lib.mkOption {
          type = lib.types.nullOr (
            if config.enum != null then
              lib.throwIf (config.type != "string")
                "parameter `${name}`: `enum` needs `type = \"string\"`, not `${config.type}`."
                (lib.types.enum config.enum)
            else
              {
                string = lib.types.str;
                integer = lib.types.int;
                boolean = lib.types.bool;
              }
              .${config.type}
          );
          default = null;
          description = ''
            Value of the parameter if the user does not set it.

            If this is `null`, the environment variable is not set by default.
          '';
        };

        enum = lib.mkOption {
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
          default = null;
          description = "Permitted values of a parameter of type `string`.";
        };

        flag = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Command line flag that gets the value of the parameter.

            The service gets this flag after `process.argv`. A parameter that
            is empty or not set adds no flag. A parameter of type `boolean`
            adds only the flag, and only if the value is `true`.
          '';
          example = "--base-url";
        };
      };
    }
  );

  toEnvironmentValue = value: if lib.isBool value then lib.boolToString value else toString value;
in
{
  options = {
    parameters = lib.mkOption {
      type = lib.types.attrsOf parameterType;
      default = { };
      description = ''
        Environment variables that the user of the service can change after
        build. Use this option instead of `process.environment` for each
        value that a user can configure.

        The attribute name is the name of the environment variable.
      '';
      example = lib.literalExpression ''
        {
          LOG_LEVEL = {
            description = "Verbosity of the service logs.";
            enum = [ "info" "debug" ];
            default = "info";
          };
          BASE_URL = {
            description = "Public URL of the service.";
            default = "http://localhost:8080";
            flag = "--base-url";
          };
        }
      '';
    };

    parametersSchema = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.attrsOf lib.types.anything;
      default = {
        "$schema" = "https://json-schema.org/draft/2020-12/schema";
        type = "object";
        properties = lib.mapAttrs (
          _: parameter:
          lib.filterAttrs (_: value: value != null) {
            inherit (parameter)
              description
              type
              default
              enum
              ;
          }
        ) config.parameters;
      };
      description = "JSON Schema of the parameters of the service.";
    };
  };

  config.environment = lib.mapAttrs (
    _: parameter: lib.mkDefault (toEnvironmentValue parameter.default)
  ) (lib.filterAttrs (_: parameter: parameter.default != null) config.parameters);
}
