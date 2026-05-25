{
  pkgs,
  ...
}:

{
  packages.wireguard-rs = {
    version = "0.1.4";
    description = "Userspace WireGuard VPN implementation written in Rust.";
    homePage = "https://www.wireguard.com";
    mainProgram = "wireguard-rs";
    license = "mit";

    source = {
      git = "github:WireGuard/wireguard-rs/7d84ef9064559a29b23ab86036f7ef62b450f90c";
      hash = "sha256-UlT0c0J4oY+E1UM2ElueHECjrxErIBERwiF1huLvtds=";
    };

    build.rustPackageBuilder = {
      enable = true;
      cargoHash = "sha256-EBzHu0Es0wVWYwCB95AlEC3VF1YCe/wWC/nZxOwhez0=";
    };

    build.extraAttrs = {
      doCheck = false;
    };

    test.script = ''
      output=$(wireguard-rs 2>&1 || true)
      echo "$output" | grep -i "device"
    '';
  };
}
