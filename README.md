# NGI Forge

This software is in active development. Expect backwards incompatible changes.

## Features

- Simple, type checked configuration recipes for **packages** and
  **multi-component applications** using
  [module system](https://nix.dev/tutorials/module-system/index.html)

- [Web UI](https://ngi.nixos.org)

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

## Development

Launch local development environment

```bash
nix develop
```

and choose a command from the menu e.g, `forge-ui`.

Note that to save on download bandwidth and disk size, we support different types of shells depending on the required task:

- `minimal`: only required tools
- `ui`: minimal with local UI development tools
- `ci`: minimal with CI/CD tools and checks
- `default`: all tools

To activate one of those shells, run:

```bash
nix develop .#devShells.<system>.<shell-name>
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

Get a list of packages maintained in Nixpkgs

```bash
nix eval --json -f maintainers/list-nixpkgs.nix packages
```

[![Nixpkgs build status](https://github.com/ngi-nix/forge/actions/workflows/nixpkgs-build-status.yml/badge.svg)](https://github.com/ngi-nix/forge/actions/workflows/nixpkgs-build-status.yml)

## Credits

- This software was originally started as a fork of [imincik/nix-forge](https://github.com/imincik/nix-forge).
- Application hexagonal icons are adapted from the [NLnet Hex Gallery](https://nlnet.nl/gallery/hex.html), designed by the [NLnet Foundation](https://nlnet.nl/) and [Gust (@hex@lnrs.org)](https://social.lnrs.org/@hex) for NGI Zero-funded projects.
  Individual project logos and trademarks remain the property of their respective upstream projects.
