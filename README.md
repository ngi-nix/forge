# NGI Forge

This software is in active development. Expect backwards incompatible changes.

## Features

- Simple, type checked configuration recipes for **packages** and
  **multi-component applications** using
  [module system](https://nix.dev/tutorials/module-system/index.html)

- [Web UI](https://ngi-nix.github.io/forge)

- [LLMs support](./AGENTS.md)

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

## LLM agents

LLM agents, read [these instructions](./AGENTS.md) first.

## Credits

This software was originally started as a fork of
[imincik/nix-forge](https://github.com/imincik/nix-forge).
