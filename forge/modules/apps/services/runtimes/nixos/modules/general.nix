{
  app,

  lib,
  ...
}:
{
  users.users.root.password = "root";

  services = {
    openssh.settings.PermitRootLogin = lib.mkForce "yes";
    openssh.settings.PasswordAuthentication = lib.mkForce true;
    getty.autologinUser = "root";
  };

  networking = {
    hostName = app.name;
    useDHCP = lib.mkForce true;
    firewall.enable = lib.mkForce false;
  };

  system.stateVersion = "25.11";
}
