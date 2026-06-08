# How to create an application recipe

::: {important}
For the list of all available configuration options for application recipes,
see the
[application options reference](https://ngi-nix.github.io/forge/recipe/options?s=apps).
:::

Before writing a recipe, spend some time understanding the software:

- Does it provide any GUI or CLI programs?
- Does it run any services?
- Does it depend on any external services (for example, a database)?

## Recipe file

Create the application recipe directory and recipe file:

```bash
mkdir recipes/apps/<app-name>
touch recipes/apps/<app-name>/recipe.nix
```

Add the recipe file to Git:

```bash
git add recipes/apps/<app-name>/recipe.nix
```

::: {important}
Nix can only see files tracked by Git. If the file is not added to Git, the
recipe will not be recognized.
:::

## Metadata

Start the recipe with the following content:

````nix
{
  pkgs,
  ...
}:

{
  apps.app-name = {    # lowercase with hyphens
    displayName = "My App";
    description = "Short description of the app.";
    usage = ''
      Usage instructions in markdown format.

      ```bash
      echo "with syntax highlighting"
      ```
    '';
  };

  # More configuration to be added here.
  # ...
}
````

### Links

Add a [`links`](https://ngi.nixos.org/recipe/options?p=apps&p=packages&s=apps.%3Cname%3E.links) block that contains URLs to the project source, website, and documentation.

```nix
links = {
  website = "https://www.example.com";
  docs = "https://docs.example.com";
  source = "https://github.com/example/app";
};
```

### NGI grants

If the project is
[supported by an NGI grant via NLnet](https://nlnet.nl/project/),
add a `grants` block.

In the Forge, we track: `Commons`, `Core`, `Entrust` and `Review` grants.
While the first three are current fund themes, `Review` encompasses all
non-current NGI funds (e.g. Assure, Discovery, PET, ...).

See [NLnet - Thematics Funds](https://nlnet.nl/themes/) for more information and
search in [NLnet project page](https://nlnet.nl/project/index.html) to find
grants assigned to a particular project.

```nix
ngi.grants = {
  Commons = [
    "Example 1"
    "Example 2"
  ];
  Core = [
    "Example 1"
    "Example 2"
  ];
};
```

### Icon

Add a custom icon if one is available. Otherwise, a fallback icon will be used.

```nix
icon = ./icon.svg;
```

::: {note}
Icons for some NLnet-supported projects can be found
in [this page](https://nlnet.nl/gallery/hex.html).
:::

## Programs

Add a `programs` block if the application provides GUI or CLI programs.

### Runtimes

Forge supports two program runtimes.

#### "program" runtime

The _program_ runtime is suitable for a single-executable GUI program, which is
launched automatically when the runtime command is executed.

```nix
programs = {
  runtimes.program.enable = true;
  mainPackage = pkgs.package-gui;  # launched automatically
};
```

Launch a program using the _program_ runtime:

```bash
nix run .#<app-name>.program
```

#### "shell" runtime

The _shell_ runtime drops the user into a shell environment where one or more
GUI or CLI programs are available. Programs must be launched manually.

```nix
programs = {
  runtimes.shell.enable = true;
  packages = [
    pkgs.package-gui  # GUI program available in the shell environment
    pkgs.package-cli  # CLI program available in the shell environment
  ];
};
```

Enter the _shell_ runtime environment and run a program:

```bash
nix shell .#<app-name>

program-cli
```

## Services

Add a `services` block if the application provides services. It can contain
one or more services called _service components_.

Start with runtime-independent service configuration. The only required option
is `command`, which specifies the executable to start the service. Additional
arguments are passed using the `argv` option. Services typically also need
a configuration file, which can be supplied via the `configData` option.

<!-- TODO: document `extraComponents` after [#425](https://github.com/ngi-nix/forge/issues/425) is merged. -->

```nix
services = {
  components.my-service = {
    command = pkgs.package;
    argv = [ "--config" "service.toml" ];
    configData."service.toml" = {
      source = ./service.toml;
      path = "service.toml";
    };
  };
};
```

Additionally, environment variables can be used to configure the service using
the `environment` option.

```nix
services = {
  components.my-service = {
    ...
    environment = {
      LOG_LEVEL = "info";
    }
    ...
  };
};
```

Service user and state directory (persistent data directory) are automatically
created and managed by Forge but can be customized using `user` and `stateDir`
options if required.

```nix
services = {
  components.my-service = {
    ...
    user = "root";
    stateDir = "/var/lib/foo";
    ...
  };
};
```

All service ports exposed to the user must be configured using the `ports` option. This list is
used to configure port mapping for the _container_ runtime and to configure port forwarding when
a _nixos_ system is launched in a VM.

```nix
services = {
  components.my-service = {
    ...
    ports = [
      "8080:8080"
      "8081:8081"
      "8082:8082"
    ];
    ...
  };
};
```

A pre-start script can be configured using the `preStart` option. The pre-start
script runs before service startup, including restarts. This is useful for
tasks like database migrations.

```nix
services = {
  components.my-service = {
    ...
    preStart = ''
      program makemigrations && program migrate
    '';
    ...
  };
};
```

Multiple services (service components) can be ordered using the `after` option to control
startup order.

```nix
services = {
  components.my-service-A = {
    ...
    ...
  };
  components.my-service-B = {
    ...
    after = [ "my-service-A" ];
    ...
  };
};
```

### Runtimes

Forge supports two service runtimes. At least one runtime must be enabled to
start the service.

Services are launched using the [Nimi process manager](https://github.com/weyl-ai/nimi).

Each runtime provides a `setup` option for configuring a one-time preparation script
at startup — for example, to create directory structures or copy configuration files.

#### "container" runtime

The _container_ runtime runs each service component in a separate container
using a Podman compose file automatically generated from the recipe
configuration. Nimi script is configured as a container entrypoint.

Enable the runtime and configure a setup script:

```nix
services = {
  components.my-service = {
    ...
  };

  runtimes.container.my-service = {
    enable = true;
    setup = ''
      mkdir /var/lib/my-service/data
    '';
  };
};
```

Run a configured service in bubblewrap:

```bash
nix run .#<app-name>.services.my-service
```

Nimi prints useful information about the command, arguments,
configuration files, and environment variables used to start the service.

Example of Nimi output:

```bash
nix run .#tau-app.services.tau-tower

[2026-06-08T06:39:50Z INFO  nimi::cli] Launching process manager...
[2026-06-08T06:39:50Z INFO  nimi::process_manager] Starting process manager...
[2026-06-08T06:39:50Z INFO  tau-tower] Config: tau/tower.toml -> /nix/store/l8w2spmpwm1cif4wsnjajr4q39287k2w-config.toml
[2026-06-08T06:39:50Z INFO  tau-tower] Environment: PATH=/nix/store/yssab91xhfzc5q7g3xq08afrmirljpw4-nimi-0.1.0/bin:/nix/store/9ypz3flqsrl5xl495mm8h645gadjsxi1-coreutils-9.11/bin:/nix/store/vgi1b5730cvdpv72iddlc3w1di0bsy0k-tau-tower-0.2.2-beta-unstable-2026-03-14/bin
[2026-06-08T06:39:50Z INFO  tau-tower] Environment: PWD=/var/lib/tau-tower
[2026-06-08T06:39:50Z INFO  tau-tower] Environment: SHLVL=0
[2026-06-08T06:39:50Z INFO  tau-tower] XDG_CONFIG_HOME=/tmp/nimi-config-672ed3a0b67ecd0198cabe9a92ab7e8af5710053b600a2b8c56694a8b2c9baab
[2026-06-08T06:39:50Z INFO  tau-tower] Running: /nix/store/vgi1b5730cvdpv72iddlc3w1di0bsy0k-tau-tower-0.2.2-beta-unstable-2026-03-14/bin/tau-tower
[2026-06-08T06:39:50Z DEBUG tau-tower] Broadcasting on:
[2026-06-08T06:39:50Z DEBUG tau-tower] 	http://127.0.0.1:3002/tau.ogg
```

::: {note}
This command is intended for quick iteration during application recipe
development. The service runs inside a bubblewrap sandbox without user namespace
support, so operations requiring user or group management — such as `chown
user:user` — will fail.
:::

Inspect bubblewrap command:

```bash
cat $(nix build .#<app-name>.services.<service> --no-link --print-out-paths)/bin/<service-name>-service-sandbox
```

When services work as expected, run the entire application in containers:

```bash
nix run .#<app-name>.container
```

#### Debugging

Build container artifacts (required for next steps):

```bash
nix build .#<app-name>.container --out-link build-container
```

Inspect run scripts:

```bash
tree ./build-container/
```

Inspect compose file:

```bash
podman-compose -f ./build-container/<app-name>/compose.yaml config
```

Inspect container image:

```bash
./build-container/bin/build-oci-images

podman load < <service-name>.tar
podman inspect localhost/<service-name>
```

Inspect service in a running container:

```bash
nix run .#<app-name>.container
podman-compose -f build-container/<service-name>/compose.yaml exec <service-name> sh

# Run commands in container
# ...
```

#### "nixos" runtime

The _nixos_ runtime runs all services inside a NixOS machine. Each service
component maps to a systemd unit which is launching a Nimi script.

Enable the runtime and configure a setup script:

```nix
services = {
  components.my-service = {
    ...
  };

  runtimes.nixos.my-service = {
    enable = true;
    setup = ''
      mkdir /var/lib/my-service/data
    '';
  };
};
```

Add additional NixOS services when required:

```nix
services = {
  components.my-service = {
    ...
  };

  runtimes.nixos.my-service = {
    enable = true;
    ...
    nixosConfig = ''
      services.postgresql.enable = true;
    '';
  };
};
```

<!-- TODO: document `extraComponents` after [#425](https://github.com/ngi-nix/forge/issues/425) is merged. -->

Run the application in a NixOS VM:

```bash
nix run .#<app-name>.vm
```

#### Debugging

Build VM artifacts (required for next steps):

```bash
nix build .#<app-name>.vm --out-link build-vm
```

Inspect run scripts:

```bash
tree ./build-vm/
```

Inspect service in a running VM:

```bash
nix run .#<app-name>.vm

# Run commands in VM
journalctl --unit <service-name>.service
systemctl show <service-name>.service
```

## Tests

Add test scripts to verify that programs and services work correctly:

```nix
test.programs = {
  script = ''
    program --help | grep "Usage: program"
  '';
};

test.services = {
  script = ''
    curl="curl --retry 5 --retry-max-time 120 --retry-all-errors"

    $curl --location localhost:8180 | grep --quiet "My App" >/dev/null
  '';
};
```

Run all tests:

```bash
nix build .#<app-name>.test --print-build-logs
```

Run program test:

```bash
nix build .#<app-name>.test-programs --print-build-logs
```

Run service test:

```bash
nix build .#<app-name>.test-services-container --print-build-logs
nix build .#<app-name>.test-services-nixos --print-build-logs
```
