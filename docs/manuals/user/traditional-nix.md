# Traditional Nix

This section covers advanced usage of NGI Forge, running applications with the traditional Nix CLI (without Flakes).

## Prerequisites

### Configure substituters

Configure Nix to trust the NGI Forge binary cache so it pulls pre-built binaries rather than building from source:

```bash
export NIX_CONFIG='substituters = https://cache.nixos.org https://ngi-forge.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ngi-forge.cachix.org-1:PK0qK+LhWt4GQVpUtPapyXWxJSM1GhtmPW6CRCoygz0='
```

## Running applications with traditional Nix

NGI Forge applications can be run using the traditional Nix CLI (`nix-shell` and `nix-build`).

In the examples below, replace `<commit>` with the desired Git commit hash or branch (e.g. `master`),
and `<app-name>` with the name of the application (e.g. `apps.beacondb`).

### Program runtime

To launch a single CLI or GUI program:

```bash
nix-shell \
  -I forge="https://github.com/ngi-nix/forge/archive/<commit>.tar.gz" \
  -p '(import <forge> {}).<app-name>.program' \
  --command <exec>
```

For example, to run BeaconDB:

```bash
nix-shell \
  -I forge="https://github.com/ngi-nix/forge/archive/master.tar.gz" \
  -p '(import <forge> {}).apps.beacondb.program' \
  --command beacondb
```

If the default executable matches the package name or no specific command is needed, the `--command` option can be omitted.

### Shell runtime

To enter a shell environment with CLI or GUI programs available:

```bash
nix-shell \
  -I forge="https://github.com/ngi-nix/forge/archive/<commit>.tar.gz" \
  -p '(import <forge> {}).<app-name>'
```

For example:

```bash
nix-shell \
  -I forge="https://github.com/ngi-nix/forge/archive/master.tar.gz" \
  -p '(import <forge> {}).apps.beacondb'
```

### Container runtime

To run application services in OCI containers:

```bash
nix-build \
  -I forge="https://github.com/ngi-nix/forge/archive/<commit>.tar.gz" \
  -E '(import <forge> {}).<app-name>.container'

./result/bin/run-container
```

To build container images manually without starting them:

```bash
nix-build \
  -I forge="https://github.com/ngi-nix/forge/archive/<commit>.tar.gz" \
  -E '(import <forge> {}).<app-name>.container'

./result/bin/build-oci-images
```

### NixOS VM runtime

To run application services in a local NixOS virtual machine:

```bash
nix-build \
  -I forge="https://github.com/ngi-nix/forge/archive/<commit>.tar.gz" \
  -E '(import <forge> {}).<app-name>.vm'

./result/bin/run-<app-name>-vm
```
