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

### SSH host key

Generate the SSH host key of the target machine before the deployment. It is
installed on the target machine together with the NixOS system (see
[NixOS deployment](#nixos-deployment)), so that the
[application secrets](#application-secrets) can be encrypted for it, also
later after the deployment.

```bash
mkdir -p host-keys/etc/ssh
ssh-keygen -t ed25519 -N "" -C root@my-app -f host-keys/etc/ssh/ssh_host_ed25519_key
```

```{warning}
Keep the private key `host-keys/etc/ssh/ssh_host_ed25519_key` safe and don't
commit it to git. Anyone with the key can decrypt the secrets.
```

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

### Application secrets

Some applications need secrets, such as an admin password or a key for signing
session cookies. Application recipe provides an insecure default value, so
that the application works out of the box in a VM or in containers. Example
deployment configuration uses these default values too, so that it can be
deployed without any further steps.

```{warning}
The default values are publicly known and stored in the Nix store, where all
users of the machine can read them. Replace them before deploying the
application to production. Until then, the evaluation of the NixOS system prints
a warning which lists the secrets that still use their default values.
```

Manage the secrets with a secrets management tool, such as
[agenix](https://github.com/ryantm/agenix) or
[sops-nix](https://github.com/Mic92/sops-nix). Both tools store the secrets
encrypted next to `flake.nix`, so they can be committed to git, and decrypt them
on the target machine with its SSH host key. The application services read the
decrypted secret files using systemd's `LoadCredential`.

The secrets are encrypted for the SSH host key of the target machine, generated
before the deployment (see [SSH host key](#ssh-host-key)).

#### agenix

1. Add the agenix input and its NixOS module to `flake.nix`:

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

2. In an `agenix-rules.nix` file, list the public keys which can decrypt each secret:
   the SSH host key of the target machine
   (`host-keys/etc/ssh/ssh_host_ed25519_key.pub`), and your own SSH key to be
   able to edit the secret later:

   ```nix
   {
     "my-app-secret-key.age".publicKeys = [
       "ssh-ed25519 AAAA... root@my-app"
       "ssh-ed25519 AAAA... user@host"
     ];
   }
   ```

3. In the directory with the `agenix-rules.nix` file, create the encrypted
   secret file and add both files to git:

   ```bash
   nix run github:ryantm/agenix -- -e my-app-secret-key.age
   git add agenix-rules.nix my-app-secret-key.age
   ```

4. Add a module for the secrets to the `modules` list in `flake.nix`. It
   declares the encrypted secret file, and sets the application secret to the
   path of the decrypted secret (`config` gives access to the path):

   ```nix
   modules = [
     ...

     # Application secrets
     (
       { config, ... }:
       {
         age.secrets.my-app-secret-key.file = ./my-app-secret-key.age;

         forge.apps.my-app.secrets.my-service.secret-key = config.age.secrets.my-app-secret-key.path;
       }
     )
   ];
   ```

The deployment directory then contains:

```text
.
├── flake.nix
├── agenix-rules.nix
├── my-app-secret-key.age    # encrypted secret
└── host-keys/               # SSH host key of the target machine (not in git)
    └── etc/ssh/
        ├── ssh_host_ed25519_key
        └── ssh_host_ed25519_key.pub
```

and the agenix configuration is in these parts of `flake.nix`:

```nix
# flake.nix
{
  inputs.agenix.url = "github:ryantm/agenix";
  inputs.agenix.inputs.nixpkgs.follows = "forge/nixpkgs";
  ...

  outputs =
    inputs@{ self, ... }:
    inputs.forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      ...

      # NixOS system configuration
      flake.nixosConfigurations.my-app = inputs.forge.inputs.nixpkgs.lib.nixosSystem {
        ...
        modules = [
          ...

          # Application module
          self.packages.x86_64-linux.apps.my-app.nixosModules.default

          # Secrets management
          inputs.agenix.nixosModules.default

          # Application secrets
          (
            { config, ... }:
            {
              age.secrets.my-app-secret-key.file = ./my-app-secret-key.age;

              forge.apps.my-app.secrets.my-service.secret-key = config.age.secrets.my-app-secret-key.path;
            }
          )
        ];
      };

      ...
    };
}
```

#### sops-nix

1. Add the sops-nix input and its NixOS module to `flake.nix`:

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

2. sops-nix uses age keys. Convert the SSH host key of the target machine to an
   age key:

   ```bash
   nix run nixpkgs#ssh-to-age < host-keys/etc/ssh/ssh_host_ed25519_key.pub
   ```

   To be able to edit the secrets later, create your own age key, and print its
   public key:

   ```bash
   mkdir -p ~/.config/sops/age
   nix shell nixpkgs#age --command age-keygen -o ~/.config/sops/age/keys.txt
   nix shell nixpkgs#age --command age-keygen -y ~/.config/sops/age/keys.txt
   ```

3. In a `.sops.yaml` file, list the age keys which can decrypt the secrets: the
   key of the target machine and your own key:

   ```yaml
   creation_rules:
     - path_regex: secrets\.yaml$
       age: age1...,age1...
   ```

4. Create the encrypted `secrets.yaml` file with the secret, and add both files
   to git. The command opens an editor with a YAML file, where you add the
   secret (e.g. `my-service: { secret-key: <value> }`):

   ```bash
   nix run nixpkgs#sops -- secrets.yaml
   git add .sops.yaml secrets.yaml
   ```

5. Add a module for the secrets to the `modules` list in `flake.nix`. It
   declares the encrypted secrets file and the secret, and sets the application
   secret to the path of the decrypted secret (`config` gives access to the
   path):

   ```nix
   modules = [
     ...

     # Application secrets
     (
       { config, ... }:
       {
         sops.defaultSopsFile = ./secrets.yaml;
         sops.secrets."my-service/secret-key" = { };

         forge.apps.my-app.secrets.my-service.secret-key = config.sops.secrets."my-service/secret-key".path;
       }
     )
   ];
   ```

The deployment directory then contains:

```text
.
├── flake.nix
├── .sops.yaml
├── secrets.yaml             # encrypted secrets
└── host-keys/               # SSH host key of the target machine (not in git)
    └── etc/ssh/
        ├── ssh_host_ed25519_key
        └── ssh_host_ed25519_key.pub
```

and the sops-nix configuration is in these parts of `flake.nix`:

```nix
# flake.nix
{
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "forge/nixpkgs";
  ...

  outputs =
    inputs@{ self, ... }:
    inputs.forge.inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      ...

      # NixOS system configuration
      flake.nixosConfigurations.my-app = inputs.forge.inputs.nixpkgs.lib.nixosSystem {
        ...
        modules = [
          ...

          # Application module
          self.packages.x86_64-linux.apps.my-app.nixosModules.default

          # Secrets management
          inputs.sops-nix.nixosModules.sops

          # Application secrets
          (
            { config, ... }:
            {
              sops.defaultSopsFile = ./secrets.yaml;
              sops.secrets."my-service/secret-key" = { };

              forge.apps.my-app.secrets.my-service.secret-key = config.sops.secrets."my-service/secret-key".path;
            }
          )
        ];
      };

      ...
    };
}
```

```{note}
Containers (`nix run .#apps.my-app.container`) and the NixOS VM of the
application (`nix run .#apps.my-app.vm`) always use the default values of the
secrets. They are meant for evaluating and testing the application.
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

The `--extra-files` option installs the generated SSH host key (see
[SSH host key](#ssh-host-key)) together with the system:

```bash
nixos-anywhere --extra-files host-keys --flake .#my-app --target-host root@<ip-address>
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
