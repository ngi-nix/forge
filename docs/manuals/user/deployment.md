# Deployment

NGI Forge applications can be deployed to a physical or virtual machine as a
complete [NixOS](https://nixos.org/) system. The deployment consists of three
steps:

1. Create a NixOS system configuration including the application.
2. Describe disk partitioning with [disko](https://github.com/nix-community/disko).
3. Install the system on a remote machine with
   [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

Ready to use instructions for each application are available in the
[NGI Forge web UI](https://ngi.nixos.org) after clicking the **Deploy** button.

```{note}
Deployment requires [Nix with Flakes](prerequisites.md#install-nix-with-flakes-included-recommended).
```

## Configuration

The deployment configuration is a [Nix Flake](https://nix.dev/concepts/flakes)
stored in a `flake.nix` file in an empty directory. It uses NGI Forge as an
input and defines:

- **NixOS system configuration** (`flake.nixosConfigurations.<app-name>`) -
  the operating system of the target machine, consisting of a list of NixOS
  modules: disk partitioning, boot loader, remote access and the application
  module.
- **Application configuration** (`perSystem.forge.<app-name>`) - custom
  configuration of the application.
- **User access configuraion** (`users.users.root.openssh.authorizedKeys.keys`)
  public SSH key used to log in to the deployed machine.
- **Deployment environment** (`perSystem.devShells.default`) - tools needed
  for the deployment.

### Disk partitioning

[disko](https://github.com/nix-community/disko) describes disk partitioning,
formatting and mounting declaratively as a part of the NixOS configuration. The
same description is used to partition the disk during installation and to
generate the `fileSystems` configuration of the installed system.

The example configuration above creates a GPT partition table on the
`/dev/sda` disk with three partitions:

| Partition | Size            | Purpose                                                               |
| --------- | --------------- | --------------------------------------------------------------------- |
| `boot`    | 1 MB            | BIOS boot partition (`EF02`) used by GRUB on legacy BIOS systems      |
| `ESP`     | 512 MB          | EFI system partition (`EF00`) formatted as `vfat`, mounted to `/boot` |
| `root`    | remaining space | root filesystem formatted as `ext4`, mounted to `/`                   |

Together with the GRUB configuration (`efiSupport` and `efiInstallAsRemovable`),
this layout boots on both legacy BIOS and UEFI machines.

Adjust `disko.devices.disk.main.device` to match the disk of the target
machine. Run `lsblk` on the target machine to list available disks (for
example `/dev/sda`, `/dev/vda` or `/dev/nvme0n1`).

See the [disko examples](https://github.com/nix-community/disko/tree/master/example)
for other layouts, such as LVM, LUKS encryption, RAID or ZFS.

### Test configuration

Evaluate the configuration to quickly check it for errors:

```bash
nix eval .#nixosConfigurations.my-app.config.system.build.toplevel
```

Then test the configuration in a local virtual machine:

```bash
nix run .#nixosConfigurations.my-app.config.system.build.vm
```

### Deployment environment

The deployment configuration also defines a development shell
(`perSystem.devShells.default`) containing all tools needed for the
deployment:

- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) - installs
  NixOS on the target machine
- [nixos-rebuild](https://nixos.org/manual/nixos/stable/#sec-changing-config) -
  updates the deployed system
- [hcloud](https://github.com/hetznercloud/cli) - manages Hetzner Cloud servers
  (Hetzner Cloud deployment only)

Launch the deployment environment in the directory containing `flake.nix`:

```bash
nix develop
```

All commands in the following sections are expected to run in this
environment.

## Deployment

### Bare metal preparation

1. Download the NixOS **Minimal ISO image** for your machine architecture from
   the [NixOS download page](https://nixos.org/download/#nixos-iso).

2. Write the image to a USB flash drive (replace `/dev/sdX` with the USB drive
   device, all data on it will be erased):

```bash
sudo dd if=nixos-minimal-<version>-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

3. Boot the target machine from the USB flash drive.

4. In the installer console, set a password for the `root` user to enable
   SSH login and find out the machine IP address:

```bash
sudo passwd root
ip address
```

### Hetzner Cloud preparation

1. Create an API token in the [Hetzner Cloud Console](https://console.hetzner.cloud/)
   and upload your public SSH key.

2. Create a server running Ubuntu:

```bash
export HCLOUD_TOKEN=<api-token>

hcloud server create \
  --name my-app \
  --type <server-type> \
  --image ubuntu-24.04 \
  --ssh-key <ssh-key-name>
```

### NixOS deployment

1. Replace Ubuntu with NixOS by running the nixos-anywhere command above with
   the IP address of the created server.

[nixos-anywhere](https://github.com/nix-community/nixos-anywhere) installs
NixOS on a remote machine over SSH. The target machine must be running any
Linux system (for example Ubuntu) or a rescue system, and must be reachable as
`root` over SSH with your SSH key.

nixos-anywhere boots the target machine into a temporary NixOS installer
(using kexec), partitions and formats the disks with disko, installs the NixOS
system configuration and reboots into it.

```{warning}
All data on the target machine disk will be erased.
```

```bash
nixos-anywhere --flake .#my-app --target-host root@<ip-address>
```

After the deployment finishes, log in to the machine with:

```bash
ssh root@<ip-address>
```

## Update

To apply configuration changes to an already deployed machine, use
`nixos-rebuild` instead of reinstalling the system:

```bash
nixos-rebuild switch --flake .#my-app --target-host root@<ip-address>
```

## Security hardening

The default deployment configuration allows `root` user to log in over SSH,
which is convenient for the initial installation. For a machine exposed to the
internet, it is recommended to apply the following basic hardening steps.

### Create an administrator user

Instead of logging in as `root`, create a regular `admin` user with
administrator (`sudo`) privileges and your public SSH key. Add the following
configuration to the `Boot, remote access and firewall` module in `flake.nix`:

```nix
users.users.admin = {
  isNormalUser = true;
  extraGroups = [ "wheel" ]; # allow to use sudo
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... user@host"
  ];
};

# Allow to use sudo without password (the user has no password set)
security.sudo.wheelNeedsPassword = false;

# Allow administrators to deploy system updates
nix.settings.trusted-users = [ "@wheel" ];
```

### Disable root login and password authentication

Allow SSH login only with SSH keys and only for regular users. Replace the
`users.users.root.openssh.authorizedKeys.keys` list in `flake.nix` with the
following configuration:

```nix
users.users.root.openssh.authorizedKeys.keys = [ ];

services.openssh.settings = {
  PermitRootLogin = "no";
  PasswordAuthentication = false;
  KbdInteractiveAuthentication = false;
};
```

### Block brute-force attacks

[fail2ban](https://github.com/fail2ban/fail2ban) monitors SSH login attempts
and temporarily bans IP addresses with too many failed attempts:

```nix
services.fail2ban.enable = true;
```

### Firewall

The firewall is enabled by default. The deployment configuration opens only
the SSH port and the ports used by the application services
(`networking.firewall.allowedTCPPorts`). Don't open any additional ports unless
they are required.

### Apply the changes

Apply the configuration changes as `root` user for the last time:

```bash
nixos-rebuild switch --flake .#my-app --target-host root@<ip-address>
```

```{warning}
Before closing the current SSH session, verify that you can log in as the
`admin` user (`ssh admin@<ip-address>`), otherwise you may lose access to the
machine.
```

From now on, log in and deploy updates as the `admin` user:

```bash
ssh admin@<ip-address>

nixos-rebuild switch --flake .#my-app --target-host admin@<ip-address> --sudo
```
