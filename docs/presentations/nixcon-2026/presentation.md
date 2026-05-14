---
title: NGI Forge — Software Distribution Platform for NGI projects
theme: solarized
highlightTheme: nord
---

# NGI Forge
## Software Distribution Platform for NGI projects

NixCon, Kraków, Poland, 2026

**Ivan Mincik (@imincik)**,
**Daniel Ramirez (@wamirez)**,
**Fedi Jamoussi (@eljamm)**,
**Katepalli Phani Rithvij (@phanirithvi)**,
**Julien Moutinho (@ju1m)**

---

## Intro

---

### NGI (Next Generation Internet) program

The Next Generation Internet (NGI) is a European Commission (EC) initiative that
aims to shape the development and evolution of the Internet into an Internet
of Trust.

https://www.ngi.eu/about/

---

### NGI Zero


NGI Zero is an idea-driven consortium of not-for-profit organisations from across
Europe.

https://www.ngi.eu/ngi-projects/ngi-zero/

---

### NixOS Foundation

NGI Zero consortium partner.

https://nixos.org/

---

### NLnet Foundation

NGI Zero consortium leader

* 1000+ funded free software projects (1800+ grants)

https://nlnet.nl/

---

### Nix@NGI Team at NixOS Foundation

"Impossible" task: package all NGI-funded projects with Nix

https://nixos.org/community/teams/ngi/

---

## Problem

---

How to package 1000+ projects funded by 1800+ NLnet grants ?

---

How to sustainably maintain 1000+ projects in a long run ?

---

## Idea

---

Distribute packaging and maintenance effort.

Note:
Build packaging and software distribution platform which is intuitive and attractive to contributors and users.

Replace text with image.

---

## Goal

Build an **intuitive** packaging and software distribution platform providing **attractive additional values** for contributors and end users

---

### Intuitive - contributors

* Packaging workflow looks like a normal software build

Note:
* Packaging makes sense to an average software developer
  * experience with building a software
  * zero Nix experience

---

### Intuitive - users

* Application can be launched in a few straightforward steps

---

### Attractive - contributors

* Development environment is build-in

* Software runs directly from upstream Git repository

---

### Attractive - users

* Platform provides a rich catalog of useful software

* Software runs in standard IT industry environments (containers)

---

## NGI Forge

---

### Features

* Intuitive, type checked configuration recipes for **packages** and
  **multi-component applications** using the module system

* **Program**, **shell**, **container** and **NixOS** runtimes

---

## User interface

---

### NGI software catalogue

![all-apps](images/all-apps.png)

---

### Offen

![offen](images/offen.png)

Note:
FIXME: update app usage instructions

---

### Run offen in container

![offen-run-container](images/offen-run-container.png)

---

### Run offen in NixOS

![offen-run-nixos](images/offen-run-nixos.png)

---

### Run offen in container

```bash
nix run github:ngi-nix/forge/f00365b4#apps.offen.container

Creating container image /home/imincik/.cache/ngi-forge/e70cdb81/offen-offen-j3g9by1lj3mk3p9yclhzpbx15y9y36rr.tar ... done.
Loaded image: localhost/offen-offen:j3g9by1lj3mk3p9yclhzpbx15y9y36rr

[offen] | [2026-09-03T09:36:59Z INFO  nimi::cli] Launching process manager...
[offen] | [2026-09-03T09:36:59Z INFO  nimi::process_manager] Starting process manager...
[offen] | [2026-09-03T09:36:59Z INFO  offen] Running: /nix/store/hglbmavg7kjvpv36yy247dzms37xk53h-offen-1.4.2-unstable-2026-06-11/bin/offen serve
```

![offen-run-running](images/offen-running.png)

---

## Contributor interface

---

### Package

`recipes/pkgs/offen/recipe.nix`

```nix
  pkgs.offen = {
    # place for package configuration
  }
```
---

### Metadata

```nix
  version = "1.4.2-unstable-2026-06-11";
  description = "Fair and privacy-focused web analytics.";
  homePage = "https://www.offen.dev";
  mainProgram = "offen";
```

---

### Source

```nix
  source = {
    git = "github:offen/offen/ec99082a37ffb5855bd84debfef227d41c7b403c";
    hash = "sha256-EGlqD3611sG3YTVe74H49PB8Hj1NsKYhLANg5VAQ0wg=";
  };
```

---

### Build

```nix
  build.goPackageBuilder = {
    enable = true;
    vendorHash = "sha256-AeQa5oaOEB/50aPCRq702vMEtEctwP+jU5C6zB+3XR0=";
    ldflags = [
      "-s"
      "-w"
    ];
    modRoot = "server";
  };
```

---

### Test

```nix
  test.script = ''
    offen --help
  '';
```

---

### Application

`recipes/apps/offen/recipe.nix`

```nix
  apps.offen = {
    # place for application configuration
  }
```
---

### Metadata

```nix
  displayName = "Offen";
  description = "Fair and privacy-focused web analytics.";
  usage = ''
    Offen is a self-hosted web analytics server that gives operators insight
    into usage while allowing users to access, review, and delete their own data.
  ...
  '';
```

---

### Services

```nix
  services = {
    components.offen = {
      process.command = pkgs.offen;
      process.argv = [ "serve" ];
      process.environment = {
        OFFEN_SERVER_PORT = "3000";
        OFFEN_DATABASE_DIALECT = "sqlite3";
        OFFEN_DATABASE_CONNECTIONSTRING = "/var/lib/offen/offen.db";
      };
      process.ports = [ "3000:3000" ];
    };

    runtimes = {
      container.enable = true;
      nixos.enable = true;
    };
  };
```

---

### Test

```nix
  test.services.script = ''
    curl localhost:3000 | grep "Offen Fair Web Analytics"
  '';
```

---

## Additional values for upstream developers

---

### Built-in development environment

```bash
nix develop .#pkgs.offen.env

Welcome. This environment contains all dependencies required
to build offen from source.

Grab the source code from /nix/store/agx01h4fykiwmy7p18w0a50rzpqhcg9n-source
or from the upstream repository and you are all set to start hacking.
```

```bash
cp -r --no-preserve=mode,ownership
  /nix/store/agx01h4fykiwmy7p18w0a50rzpqhcg9n-source
  src

cd src/server

go build -o offen ./cmd/offen
```

```bash
./offen demo
```
---

### Development environment for upstream repository

```bash
cd <source-code-repository>
```

```bash
nix flake init --template github:ngi-nix/forge#developer

nix develop
```

---

### Run programs directly from upstream repository

```bash
nix run github:<owner>/<repo>#package
```

---

## Self-hosting

```bash
nix flake init --template github:ngi-nix/forge#provider
```

---

## Packaging in Nixpkgs


```nix
  meta.teams = [ lib.teams.ngi ];
```

Note:
* NGI software is either packaged in NGI Forge or in Nixpkgs
* Nixpkgs packages are re-exported as Forge apps

---

## How to contribute

TODO

---

## Thanks

TODO

---

## Try yourself

https://ngi.nixos.org/
