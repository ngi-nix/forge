{
  lib,
  ...
}@args:
{
  imports = [ (import ./base.nix args) ];

  users.users.root.password = "root";

  services = {
    openssh.settings.PermitRootLogin = lib.mkForce "yes";
    openssh.settings.PasswordAuthentication = lib.mkForce true;
    getty.autologinUser = "root";
  };

  networking = {
    useDHCP = lib.mkForce true;
    firewall.enable = lib.mkForce false;
  };
}
