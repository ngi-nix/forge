{
  lib,
  ...
}:
{
  options = {
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port number of the endpoint.";
      example = 8000;
    };

    protocol = lib.mkOption {
      type = lib.types.str;
      default = "http";
      description = ''
        Application-level protocol of the endpoint, such as `http`, `https`,
        `websocket` or `postgresql`.
      '';
      example = lib.literalExpression ''"postgresql"'';
    };

    visibility = lib.mkOption {
      type = lib.types.enum [
        "private"
        "public"
      ];
      default = "private";
      description = ''
        Visibility of the endpoint.

        - `private` (default): the endpoint is only used by the other service
          components and resources of the app.

        - `public`: the endpoint is meant to be exposed to the users of the app.
      '';
      example = lib.literalExpression ''"public"'';
    };
  };
}
