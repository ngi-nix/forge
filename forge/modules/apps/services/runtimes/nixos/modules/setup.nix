{
  app,

  config,
  lib,
  ...
}:
{
  systemd.services."${app.name}-setup" = lib.mkIf (config.setup != "") {
    description = "Setup service for ${app.name}.";
    wantedBy = [ "multi-user.target" ];
    before = [ "multi-user.target" ];
    after = [ "network.target" ];
    script = config.setup;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
