{
  lib,
  ...
}:
{
  options = {
    endpoints = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ./endpoint.nix);
      default = { };
      description = ''
        Endpoints exposed to the users of the app, by name.

        All endpoints are forwarded to the host by the container and NixOS VM
        runtimes and opened in the firewall of deployed machines.
      '';
      example = lib.literalExpression ''
        {
          web.port = 8000;
        }
      '';
    };
  };
}
