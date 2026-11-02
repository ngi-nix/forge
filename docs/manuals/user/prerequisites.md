# Prerequisites

Linux is currently the only supported operating system for NGI Forge and
requires the following tools to be installed.

## Nix

The most important requirement of NGI Forge is [Nix](https://nixos.org/).
We recommend using the new [Nix CLI and Flakes](https://nix.dev/concepts/flakes).
For traditional Nix setup without Flakes, see the [traditional-nix](traditional-nix.md) section.

### Install Nix with Flakes included

1. Install Nix with new CLI and Flakes enabled:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

2. Accept binaries pre-built by NGI Forge (optional, highly recommended):

```bash
export NIX_CONFIG="accept-flake-config = true"
```

### Uninstall

Run the following command to uninstall Nix:

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

On Debian/Ubuntu:

```bash
sudo apt install podman podman-compose
```

On NixOS, follow the [Podman setup instructions on the NixOS Wiki](https://wiki.nixos.org/wiki/Podman).

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

If the kvm module is missing, enable virtualization in your BIOS/UEFI settings and
ensure the KVM kernel modules are loaded:

```bash
sudo modprobe kvm_intel   # Intel CPUs
sudo modprobe kvm_amd     # AMD CPUs
```
