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

  # The VM is for evaluation, the default values of secrets are used
  # (the secret files of a deployment do not exist in the VM).
  forge.apps.${app.name}.useDefaultSecrets = true;

  system.stateVersion = "25.11";
}
