{
  lib,
  ...
}:
{
  options = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of packages available in the test script.";
      example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
    };

    script = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Script to test the program runtime.

        Launch tests with:

        ```
        nix build .#<app>.test-programs
        ```
      '';
      example = ''
        $program --version
      '';
    };
  };
}
