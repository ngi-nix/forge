# How to clean-up your system

Building and running NGI Forge packages and applications leaves different types
of files on your system. This page lists what gets created and how to remove it.

## Nix Store

Running any `nix` command (e.g. `nix build`, `nix run`) adds paths to the Nix
store, located in the `/nix/store` directory, containing all dependencies and
build results. This is a core principle of Nix. It is safe to remove any
paths that are no longer used.

Clean-up command:

```bash
nix store gc -v
```

### "result" symlink

Running the `nix build` command leaves `result` symlinks in the directory the
command was run from. These symlinks point to the build result's store path
in `/nix/store`.

Clean-up command:

```bash
rm -fv result result-*
```

## Container runtime

### Image cache

Running applications in the `container` runtime using `nix run
.#apps.<name>.container` leaves container image tarballs in the
`$XDG_CACHE_HOME/ngi-forge` directory, to be reused on future runs. It is safe
to remove them any time.

Clean-up command:

```bash
rm -rfv "${XDG_CACHE_HOME:-$HOME/.cache}/ngi-forge"
```

### Podman images

The `container` runtime loads built images into `podman`.

Clean-up command:

```bash
podman rmi -f $(podman images --filter "label=ngi-forge=true" -q)
```

## NixOS runtime

Running applications in the `nixos` runtime using `nix run
.#apps.<name>.nixos.vm` creates a QEMU disk image, named after the app, in the
directory the command was run from. This image holds the VM's state (and
therefore the app's data), and persists across VM runs.

Clean-up command:

```bash
rm -fv ./*.qcow2
```

## Package debug builds

Following the [package recipe guide](package_recipe.md#troubleshooting), an
interactive package build environment launched with
`nix develop .#pkgs.<package-name>` is usually created in a `dev` directory.

Clean-up command:

```bash
rm -rf dev
```
