# NGI Forge 0.1 released

We are excited to announce the initial release of
[NGI Forge](https://ngi-nix.github.io/forge/), our new software packaging and
distribution system for projects supported by the
[Next Generation Internet (NGI)](https://www.ngi.eu/) initiative via
[NLnet](https://nlnet.nl/).

NGI Forge tries to lower the barrier to software packaging, making it more accessible to a
wider developer audience while preserving all the power of Nix.

Our most important goal is to build a platform which is both attractive and
accessible enough to be used by upstream NGI software authors. We expect this to significantly
increase the sustainability of packaging, especially with regards to maintenance and usability of
[those hundreds of NLnet supported projects](https://nlnet.nl/project/) and also
help us increase Nix adoption.

## Features

NGI Forge packages and applications are defined by human-readable, type-checked recipes
(see e.g. [Mox package](https://github.com/ngi-nix/forge/blob/master/recipes/packages/mox/recipe.nix)
and [Mox application](https://github.com/ngi-nix/forge/blob/master/recipes/apps/mox-app/recipe.nix)).
Currently, we support packages written in C/C++, Python, Go, Rust and we will
extend support for other languages as we keep on adding more packages.

Applications support three runtimes: a **shell environment** for CLI and GUI
programs, **OCI compatible containers**, and **NixOS** for system services.

A nice [Web UI](https://ngi-nix.github.io/forge/) lets users browse available
NGI software and run it using simple commands.

Recipes can be generated and maintained with AI assistance by following the instructions in the
[AGENTS.md file](https://github.com/ngi-nix/forge/blob/master/AGENTS.md).

NGI Forge is built to be reusable for other projects and should be very easy to
self-host using the
[Provider Flake template](https://github.com/ngi-nix/forge/tree/master/templates/provider).

## Future plans

- Add all kinds of documentation and learning materials
- Add [NixOS deployment workflow](https://github.com/ngi-nix/forge/issues/176)
- Add [support for more programming languages](https://github.com/ngi-nix/forge/issues/56)
- Add support for [application configuration via portable NixOS modules](https://github.com/ngi-nix/forge/issues/294)
- Provide [development environments for upstream projects](https://github.com/ngi-nix/forge/issues/312).
- Migrate projects from NGIpkgs repository to NGI Forge and Nixpkgs

Browse [the list of open user stories](https://github.com/orgs/ngi-nix/projects/8/views/27) to see more.

## Try it out

Visit [NGI Forge](https://ngi-nix.github.io/forge/) to browse and test the first
available applications.

Source code is available on [GitHub](https://github.com/ngi-nix/forge) and any
feedback or PRs are highly appreciated.

## Similar products

- [Conda Forge](https://conda-forge.org/)
- [Nix Software](https://nixsoftware.org/)
- [NUR](https://nur.nix-community.org/)
- [NLnet Dossiers](https://dossiers.ngi-0.eu/)

[Nix@NGI team](https://nixos.org/community/teams/ngi/).
