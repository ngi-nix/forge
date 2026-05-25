{
  pkgs,
  ...
}:

{
  apps.wireguard-rs = {
    displayName = "WireGuard-RS";
    description = "Userspace WireGuard VPN implementation written in Rust.";
    usage = ''
      wireguard-rs is a userspace implementation of the WireGuard VPN protocol.
      It creates a WireGuard tunnel on a named TUN interface.

      #### Create a WireGuard tunnel interface

      ```bash
      wireguard-rs <interface-name>
      ```

      #### Configure the interface with wg(8)

      ```bash
      wg setconf <interface-name> /etc/wireguard/<interface-name>.conf
      ```

      _Available in: shell._
    '';

    links = {
      website = "https://www.wireguard.com";
      source = "https://github.com/WireGuard/wireguard-rs";
    };

    ngi.grants = {
      Entrust = [
        "WireGuard-SpinalHDL"
        "Wireguard-Rust"
      ];
      Review = [
        "WireGuard-upscale"
        "wireguard-scaleup"
      ];
    };

    programs = {
      packages = [
        pkgs.wireguard-rs
      ];

      runtimes.shell = {
        enable = true;
      };
    };

    test.programs.script = ''
      output=$(wireguard-rs 2>&1 || true)
      echo "$output" | grep -i "device"
    '';
  };
}
