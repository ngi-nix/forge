{
  lib,
  ...
}:

{
  apps.offen = {
    description = lib.mkForce "Custom offen service configuration.";
    services.components.offen.process = {
      environment.OFFEN_SERVER_PORT = lib.mkForce "9000";
      ports = lib.mkForce [ "9000:9000" ];
    };
  };
}
