# Prerequisites

Linux is currently the only supported operating system for NGI Forge and
requires following tools to be installed.

## Nix

The most important requirement of NGI Forge is [Nix](https://nixos.org/).
NGI Forge can be used with or without the new
[Nix CLI and Flakes](https://nix.dev/concepts/flakes) - both modes are supported.

### Install Nix with Flakes included (recommended)

1. Install Nix with new CLI and Flakes enabled:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

2. Accept binaries pre-built by NGI Forge (optional, highly recommended):

```bash
export NIX_CONFIG="accept-flake-config = true"
```

### Install Nix with traditional CLI

1. Install Nix without Flakes:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

2. Configure substituters (optional, highly recommended):

```bash
export NIX_CONFIG='substituters = https://cache.nixos.org https://ngi-forge.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0='
```

### Uninstall

Run following command to uninstall Nix:

```bash
/nix/nix-installer uninstall
```

## Podman

[Podman](https://podman.io/) and [podman-compose](https://github.com/containers/podman-compose)
are required for running applications in containers. Install them using your
system package manager, for example on Fedora/RHEL:

```bash
sudo dnf install podman podman-compose
```

Or on Debian/Ubuntu:

```bash
sudo apt install podman podman-compose
```

## KVM

Running applications in a NixOS VM requires
[KVM](https://linux-kvm.org/page/Main_Page). This needs:

- A CPU with hardware virtualization support (Intel VT-x or AMD-V)
- KVM kernel modules loaded (`kvm_intel` or `kvm_amd`)
- User access to `/dev/kvm`

Verify KVM is available:

```bash
lsmod | grep kvm
```

If kvm module is missing, enable virtualization in your BIOS/UEFI settings and
ensure the KVM kernel modules are loaded:

```bash
sudo modprobe kvm_intel   # Intel CPUs
sudo modprobe kvm_amd     # AMD CPUs
```
