{ lib, ... }:
{
  options = {
    enable = lib.mkEnableOption "health check";

    test = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Command to run to check health, as a list of strings (direct exec, no shell).
      '';
      example = lib.literalExpression ''[ "''${lib.getExe pkgs.curl}" "-fs" "http://localhost:5000/" ]'';
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        List of packages available to the health check command.
      '';
      example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
    };
    interval = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      description = "Time between health checks.";
      example = "1m";
    };
    timeout = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      description = "Time to wait for a health check to succeed before considering it failed.";
      example = "10s";
    };
    startPeriod = lib.mkOption {
      type = lib.types.str;
      default = "0s";
      description = "Initialization period during which health check failures are not counted.";
      example = "30s";
    };
    retries = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Number of consecutive failures needed to consider the service unhealthy.";
      example = 5;
    };
  };
}
