{
  lib,
  ...
}:
{
  options = {
    value = lib.mkOption {
      type = lib.types.oneOf [
        lib.types.str
        lib.types.int
        lib.types.bool
      ];
      description = "Value of the parameter.";
      example = 8080;
    };
    description = lib.mkOption {
      type = lib.types.str;
      description = "Description of the parameter.";
      example = "Port of the web interface.";
    };
  };
}
