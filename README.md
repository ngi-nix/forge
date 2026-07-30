# NGI Forge

This software is in active development. Expect backwards incompatible changes.

## Features

- Simple, type checked configuration recipes for **packages** and
  **multi-component applications** using
  [module system](https://nix.dev/tutorials/module-system/index.html)

- [Web UI](https://ngi-nix.github.io/forge)

- Easy [self hosting](#self-hosting)

### Conceptual diagram

```mermaid
graph TB
    subgraph NixosCommunity["NixOS Community"]
      NIXPKGS(Nixpkgs)
      NIXOS(NixOS)
    end

    subgraph Sources["Sources"]
        SW1[Git Repository]
        SW2[Tarball URL]
        SW3[Local Path]
    end

    PKG[Package Recipe<br/>recipe.nix]

    subgraph PackageOutputs["Packages"]
        PO4[Nix Package]
        PO1[Development Environment]
        PO2[Shell Environment]
    end

    APP[Application Recipe<br/>recipe.nix]

    subgraph AppOutputs["Applications"]
        AO1[Shell Runtime<br/>for CLI and GUI components]
        AO2[Container Runtime<br/>for services]
        AO3[NixOS Runtime<br/>for services]
    end

    SW1 & SW2 & SW3 & NIXPKGS--> PKG
    PKG --> PO1 & PO2 & PO4

    PO4 & NIXPKGS & NIXOS --> APP
    APP --> AO1
    APP --> AO2
    APP --> AO3
```

## Self hosting

- Initiate new Nix Forge instance from template

```bash
nix flake init --template github:ngi-nix/forge#provider
```

- Set `repositoryUrl` attribute in `flake.nix` to your repository

- Add all new files to git

- Start creating recipes in `recipes` directory

## Nixpkgs repository

We package and maintain some NGI software in
[Nixpkgs](https://github.com/NixOS/nixpkgs) and re-use it in the Forge
application recipes.

- Get a list of packages maintained in Nixpkgs

```bash
nix eval --json -f maintainers/list-nixpkgs.nix packages
```

- [![Nixpkgs build status](https://github.com/ngi-nix/forge/actions/workflows/nixpkgs-build-status.yml/badge.svg)](https://github.com/ngi-nix/forge/actions/workflows/nixpkgs-build-status.yml)

## Credits

This software was originally started as a fork of
[imincik/nix-forge](https://github.com/imincik/nix-forge).
