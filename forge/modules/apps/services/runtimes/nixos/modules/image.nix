{
  portMappings,
  ...
}@args:
{
  imports = [ (import ./base.nix args) ];

  # Do not set default credentials or disable the firewall like `general.nix` does,
  # because images can be deployed to public networks.
  # Cloud image variants get SSH keys from the metadata service of the provider.
  networking.firewall.allowedTCPPorts = map (port: port.guest) portMappings;
}
