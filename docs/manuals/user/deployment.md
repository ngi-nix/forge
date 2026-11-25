# Deployment

NGI Forge applications can be deployed to a physical or virtual machine as a
complete [NixOS](https://nixos.org/) system. The deployment consists of three
steps:

1. Create a NixOS system configuration that contains the application.
1. Describe disk partitioning with [disko](https://github.com/nix-community/disko).
1. Install the system on a remote machine with
   [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

To get started, pick an application which supports the `nixos` or `container`
runtimes from the [NGI Forge web UI](https://ngi.nixos.org) and click the
**Deploy** button in the top right.

```{note}
Deployment requires [Nix with Flakes](prerequisites.md#install-nix-with-flakes-included).
```

## Configuration

The deployment configuration is a [Nix Flake](https://nix.dev/concepts/flakes)
stored in a `flake.nix` file. It uses NGI Forge as an
input and defines:

- **NixOS system configuration** (`flake.nixosConfigurations.<app-name>`) -
  the operating system of the target machine, consisting of a list of NixOS
  modules: disk partitioning, boot loader, remote access and the application
  module.
- **Application configuration** (`perSystem.forge.apps.<app-name>`) - custom
  configuration of the application, including its parameters.
- **User access configuration** (`users.users.root.openssh.authorizedKeys.keys`)
  public SSH key used to log in to the deployed machine.
- **Deployment environment** (`perSystem.devShells.default`) - tools needed
  for the deployment.

### Disk partitioning

[disko](https://github.com/nix-community/disko) describes disk partitioning,
formatting and mounting declaratively as a part of the NixOS configuration.

The deployment configuration uses the `deployFlakeDefaultDiskoConfig` function
from NGI Forge, which creates a GPT partition table on the `device` disk with
three partitions and support to boot on both legacy BIOS and UEFI machines.

```nix
modules = [
  inputs.disko.nixosModules.disko
  (inputs.forge.lib.deployFlakeDefaultDiskoConfig { device = "/dev/sda"; })
  ...
];
```

| Partition | Size            | Purpose                                                               |
| --------- | --------------- | --------------------------------------------------------------------- |
| `boot`    | 1 MB            | BIOS boot partition (`EF02`) used by GRUB on legacy BIOS systems      |
| `ESP`     | 512 MB          | EFI system partition (`EF00`) formatted as `vfat`, mounted to `/boot` |
| `root`    | remaining space | root filesystem formatted as `ext4`, mounted to `/`                   |

For a custom layout, replace the function with your own disko configuration.
The function is equivalent to:

```nix
disko.devices.disk.main = {
  type = "disk";
  device = "/dev/sda";
  content = {
    type = "gpt";
    partitions = {
      boot = {
        size = "1M";
        type = "EF02";
      };
      ESP = {
        size = "512M";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
      root = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      };
    };
  };
};
```

The boot loader configuration matching this layout is in the
`deployFlakeDefaultBootLoaderConfig` module from NGI Forge:

```nix
modules = [
  inputs.forge.lib.deployFlakeDefaultBootLoaderConfig
  ...
];
```

It is equivalent to:

```nix
boot.loader.grub = {
  efiSupport = true;
  efiInstallAsRemovable = true;
};
```

```{warning}
Don't forget to match the main device to the disk of the target machine, where
you want to deploy. To list the available disks, run `lsblk` and choose the
appropriate one (e.g. `/dev/sda`, `/dev/vda` or `/dev/nvme0n1`).
```

See the [disko examples](https://github.com/nix-community/disko/tree/master/example)
for other layouts, such as LVM, LUKS encryption, RAID or ZFS.

### Application parameters

If the application has parameters, for example its port, the application
configuration lists them with their default values. Change a value to customize
the deployed application:

```nix
forge.apps.my-app = {
  enable = true;

  # Port of the web interface.
  parameters.port.value = lib.mkForce 9090;
};
```

The application recipe sets the default values too, hence `lib.mkForce`.

### Application secrets

If the application has secrets, for example an admin password, the application
configuration lists them. Until they are set, the application uses insecure
default values, which are stored in the Nix store and are readable by all users.
The evaluation of the system prints a warning about them.

The services load the secrets from files using systemd's `LoadCredential`. Set
the `file` of each secret in the application configuration:

```nix
forge.apps.my-app = {
  enable = true;

  # Secret key for signing session cookies.
  services.components.my-service.secrets.secret-key.file = "/run/agenix/my-app-secret-key";
};
```

Alternatively, set the secret files in the NixOS system configuration, which
overrides the application configuration:

```nix
forge.apps.my-app.secrets.my-service.secret-key = config.age.secrets.my-app-secret-key.path;
```

The secret file must not be in the Nix store. Create it with a secrets
management tool, for example [agenix](https://github.com/ryantm/agenix) or
[sops-nix](https://github.com/Mic92/sops-nix). Both tools encrypt the secrets
with the SSH host key of the target machine, so the encrypted files can be
committed to git. To get the key of the prepared machine, run:

```bash
ssh-keyscan -t ed25519 <ip-address>
```

#### agenix

Add the `agenix` input and its NixOS module to `flake.nix`:

```nix
inputs.agenix.url = "github:ryantm/agenix";
inputs.agenix.inputs.nixpkgs.follows = "forge/nixpkgs";
```

```nix
modules = [
  inputs.agenix.nixosModules.default
  ...
];
```

Allow the machine key (and your own key, to edit the secrets later) to decrypt
the secret in `secrets.nix` file:

```nix
{
  "my-app-secret-key.age".publicKeys = [
    "ssh-ed25519 AAAA... root@my-app"
    "ssh-ed25519 AAAA... user@host"
  ];
}
```

Create the secret and add it to git:

```bash
nix run github:ryantm/agenix -- -e my-app-secret-key.age
git add my-app-secret-key.age
```

Then declare the secret in the system configuration:

```nix
age.secrets.my-app-secret-key.file = ./my-app-secret-key.age;
```

and set its file in the application configuration:

```nix
services.components.my-service.secrets.secret-key.file = "/run/agenix/my-app-secret-key";
```

#### sops-nix

Add the `sops-nix` input and its NixOS module to `flake.nix`:

```nix
inputs.sops-nix.url = "github:Mic92/sops-nix";
inputs.sops-nix.inputs.nixpkgs.follows = "forge/nixpkgs";
```

```nix
modules = [
  inputs.sops-nix.nixosModules.sops
  ...
];
```

Convert the machine key to an age key, and allow it (and your own age key, to
edit the secrets later) to decrypt the secrets in `.sops.yaml` file:

```bash
ssh-keyscan -t ed25519 <ip-address> | nix run nixpkgs#ssh-to-age
```

```yaml
creation_rules:
  - path_regex: secrets\.yaml$
    age: age1...,age1...
```

Create the secrets file with the secret (e.g. `my-service: { secret-key: <value> }`)
and add it to git:

```bash
nix run nixpkgs#sops -- secrets.yaml
git add .sops.yaml secrets.yaml
```

Then declare the secret in the system configuration:

```nix
sops.defaultSopsFile = ./secrets.yaml;
sops.secrets."my-service/secret-key" = { };
```

and set its file in the application configuration:

```nix
services.components.my-service.secrets.secret-key.file = "/run/secrets/my-service/secret-key";
```

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
configuration to the `System configuration` module in `flake.nix`:

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

The firewall is enabled by default. Only the SSH port and the ports of the
application endpoints are open. The application module opens the endpoint ports
(`networking.firewall.allowedTCPPorts` and `allowedUDPPorts`), so they follow
the application parameters. Don't open any additional ports unless they are
required.

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
