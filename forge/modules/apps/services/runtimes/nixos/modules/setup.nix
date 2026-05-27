{
  app,

  config,
  lib,
  ...
}:
let
  serviceUnits = map (name: name + ".service") (lib.attrNames app.services.components);
in
{
  systemd.services."${app.name}-setup" = lib.mkIf (config.setup != "") {
    description = "Setup service for ${app.name}.";
    wantedBy = [ "multi-user.target" ];
    before = [ "multi-user.target" ] ++ serviceUnits;
    requiredBy = serviceUnits;
    after = [ "network.target" ];
    path = config.packages;
    script = config.setup;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
