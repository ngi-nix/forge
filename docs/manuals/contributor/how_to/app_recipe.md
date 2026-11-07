# How to create an application recipe

::: {important}
For the list of all available configuration options for application recipes,
see the
[application options reference](https://ngi.nixos.org/recipe/options?s=apps).
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

    # More configuration to be added here.
    # ...
  };
}
````

::: {important}
Ensure that the remainder of the application recipe is done within the `apps.app-name` block to avoid nasty infinite recursion errors.
:::

### Links

Add a
[`links`](https://ngi.nixos.org/recipe/options?p=apps&p=pkgs&s=apps.%3Cname%3E.links)
block that contains URLs to the project source, website, and documentation.

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
Hexagonal icons for NLnet-supported projects can be found in the [NLnet Hex Gallery](https://nlnet.nl/gallery/hex.html) (designed by NLnet and Gust).
These designs are adaptations of the upstream projects' logos and are [licensed](https://nlnet.nl/officehour/#:~:text=What%20is%20the%20license%20of%20the%20nice%20hexagon%20stickers) the same as the original logo.
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
nix run .#apps.<app-name>.program
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
nix shell .#apps.<app-name>

program-cli
```

## Services

Add a `services` block if the application provides services. It can contain
one or more _service components_.

Start with runtime-independent service configuration. The only required option
is `process.command`, which specifies the executable to start the service.

Additional arguments are passed using the `process.argv` option.

Services typically also need a configuration file, which can be supplied
via the `process.configData` option. Configuration files are installed
to `$XDG_CONFIG_HOME` directory, which can be referenced directly in
`process.argv`.

```nix
services = {
  components.my-service = {
    process.command = pkgs.package;
    process.argv = [ "--config" "$XDG_CONFIG_HOME/service.toml" ];
    process.configData."service.toml" = {
      source = ./service.toml;
      path = "service.toml";
    };
  };
};
```

Additionally, environment variables can be used to configure the service using
the `process.environment` option.

```nix
services = {
  components.my-service = {
    ...
    process.environment = {
      LOG_LEVEL = "info";
    };
    ...
  };
};
```

Values that a user can change after build are _parameters_. Set them with the
`process.parameters` option instead of `process.environment`. A parameter is an
environment variable with a description, a type (`string`, `integer` or
`boolean`), and optionally a default value and a list of permitted values.

If the program does not read the environment variable, use `flag` to give the
value to the program as a command line flag. The program gets the flag after
`process.argv`.

```nix
services = {
  components.my-service = {
    ...
    process.parameters = {
      LOG_LEVEL = {
        description = "Verbosity of the service logs.";
        enum = [ "info" "debug" ];
        default = "info";
      };
      BASE_URL = {
        description = "Public URL of the service.";
        default = "http://localhost:8080";
        flag = "--base-url";
      };
    };
    ...
  };
};
```

Service user and state directory (persistent data directory) are automatically
created and managed by Forge but can be customized using `process.user` and
`process.stateDir` options if required.

```nix
services = {
  components.my-service = {
    ...
    process.user = "root";
    process.stateDir = "/var/lib/foo";
    ...
  };
};
```

All service ports exposed to the user must be set using the `process.ports` option.
This list is used to configure port mapping for the _container_ runtime and to
configure port forwarding when a _nixos_ system is launched in a VM.

```nix
services = {
  components.my-service = {
    ...
    process.ports = [
      "8080:8080"
      "8081:8081"
      "8082:8082"
    ];
    ...
  };
};
```

A pre-start script can be configured using the `process.preStart` option. The
pre-start script runs before service startup, including restarts. This is useful
for tasks like database migrations.

```nix
services = {
  components.my-service = {
    ...
    process.preStart = ''
      program makemigrations && program migrate
    '';
    ...
  };
};
```

Dependencies between multiple services (service components) can be configured
using the `dependsOn` option.

```nix
services = {
  components.my-service-A = {
    ...
    ...
  };
  components.my-service-B = {
    ...
    dependsOn = [ "my-service-A" ];
    ...
  };
};
```

### Health checks

A health check can be configured for a service component using the `healthcheck`
option. When enabled, dependent services wait for the component to become healthy
before starting.

The `test` command is executed directly (no shell) so binary paths must be
fully specified. Use string interpolation to reference Nix store paths.

```nix
services = {
  components.my-service-A = {
    process = {
      ...
    };

    healthcheck = {
      enable = true;
      test = [ "${lib.getExe pkgs.curl}" "-fs" "http://localhost:8080/health" ];
      interval = "3s";
      timeout = "3s";
      startPeriod = "10s";
      retries = 10;
    };
  };
};
```

### Additional resources

Additional resources required by services - such as a database or reverse proxy
can be configured using the `resources` option.

Resources are shared by all service components. By default, a resource has
the `backend` role and starts before the components. A resource with the
`frontend` role, such as a reverse proxy, starts after the components.

```nix
services = {
  components.my-service = {
    ...
    process.command = pkgs.my-service;
    ...
  };

  resources.database.nixosConfig = {
    services.postgresql.enable = true;
  };

  resources.reverse-proxy = {
    role = "frontend";
    ports = [ "8080:8080" ];
    nixosConfig = {
      services.nginx.enable = true;
    };
  };
};
```

Resources are enabled by default. A resource can be disabled, for example when
the application should use an external database instead:

```nix
services.resources.database.enable = false;
```

### Runtimes

Forge supports two service runtimes. At least one runtime must be enabled to
start the service.

Each runtime provides a `setup` option for configuring a one-time preparation script
at startup — for example, to create directory structures or copy configuration files.

#### "container" runtime

The _container_ runtime runs each service component in a separate container
using a Podman Compose file automatically generated from the recipe
configuration. A generated script is the container entrypoint. It restarts the
service after a failure and stops the service when the container stops.

Each _component_ runs in separate single-process container, while _resources_
run in a full NixOS systemd container.

Both _components_ and _resources_ can be extended with container
runtime-specific configuration.

Enable the runtime, configure a setup script and resource configuration:

```nix
services = {
  components.my-service = {
    ...
  };

  runtimes.container = {
    enable = true;

    components.my-service.setup = ''
      mkdir /var/lib/my-service/data
    '';

    resources.database.nixosConfig = {
      services.postgresql.enableTCPIP = true;
    };
  };
};
```

Run a configured service in bubblewrap:

```bash
nix run .#apps.<app-name>.services.my-service
```

The service runner prints the configuration files and the command that it uses
to start the service.

Example of the output:

```bash
nix run .#apps.tau.services.tau-tower

Config: tau/tower.toml -> /nix/store/l8w2spmpwm1cif4wsnjajr4q39287k2w-config.toml
Running: /nix/store/vgi1b5730cvdpv72iddlc3w1di0bsy0k-tau-tower-0.2.2-beta-unstable-2026-03-14/bin/tau-tower
```

::: {note}
This command is intended for quick iteration during application recipe
development. The service runs inside a bubblewrap sandbox without user namespace
support, so operations requiring user or group management — such as `chown
user:user` — will fail.
:::

Inspect bubblewrap command:

```bash
cat $(nix build .#apps.<app-name>.services.<service> --no-link --print-out-paths)/bin/<app-name>-service-sandbox
```

When services work as expected, run the entire application in containers:

```bash
nix run .#apps.<app-name>.container
```

A user can configure a built container without Nix. The _Run_ dialog of the
application shows this configuration for each service.

- Environment variables: `podman run --env` sets a value of
  `process.parameters` or `process.environment`. `nix run` gets the values of
  `process.parameters` from the host environment.
- Configuration files: a file at `/config/<path>` in the container replaces the
  `process.configData` item with the same `path`. `nix run` mounts the
  `$FORGE_CONFIG_DIR/<service>` directory at `/config`. By default,
  `FORGE_CONFIG_DIR` is a directory of the application in the Forge cache
  directory. `podman-compose` with only `compose.yaml` does not mount `/config`.
- Arguments: the service gets the arguments after the image name of
  `podman run` after `process.argv`.

```bash
podman run --env LOG_LEVEL=debug localhost/<app-name>-<service>:latest --verbose

podman run --volume ./service.toml:/config/service.toml:ro,z \
  localhost/<app-name>-<service>:latest

LOG_LEVEL=debug FORGE_CONFIG_DIR=./config nix run .#apps.<app-name>.container
```

Use `process.references` to link to the upstream reference of the command line,
the environment variables and the configuration files. The image labels and the
_Run_ dialog show these links.

```nix
process.references = {
  commandLine = "https://example.com/docs/cli";
  environment = "https://example.com/docs/environment";
  configFile = "https://example.com/docs/configuration";
};
```

The image label `ngi-forge.parameters` contains a JSON Schema of the parameters.
The label `ngi-forge.references` contains the references:

```bash
podman image inspect --format '{{ index .Labels "ngi-forge.parameters" }}' \
  localhost/<app-name>-<service>:latest
```

#### Debugging

Build container artifacts (required for next steps):

```bash
nix build .#apps.<app-name>.container --out-link build-container
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

Inspect a running container:

```bash
nix run .#apps.<app-name>.container
podman inspect <app-name>_<TAB>
```

Inspect service in a running container:

```bash
nix run .#apps.<app-name>.container
podman-compose -f build-container/<service-name>/compose.yaml exec <service-name> sh

# Run commands in container
# ...
```

#### "nixos" runtime

The _nixos_ runtime runs all services inside a NixOS machine. Each service
component maps to a systemd unit.

All _components_ and _resources_ are running in a single NixOS system.

Components, resources, and the NixOS system itself can be extended with
runtime-specific configuration using the `nixosConfig` option.

Enable the runtime, configure a setup script, and add resource configuration:

```nix
services = {
  components.my-service = {
    ...
  };

  runtimes.nixos = {
    enable = true;

    setup = ''
      mkdir /var/lib/my-service/data
    '';

    nixosConfig = {
      services.postgresql.authentication = ''
        local all all trust
      '';
    };
  };
};
```

Run the application in a NixOS VM:

```bash
nix run .#apps.<app-name>.vm
```

#### Debugging

Build VM artifacts (required for next steps):

```bash
nix build .#apps.<app-name>.vm --out-link build-vm
```

Inspect run scripts:

```bash
tree ./build-vm/
```

Inspect service in a running VM:

```bash
nix run .#apps.<app-name>.vm

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

Use `test.services.containerScript` to test the configuration of a container
after `script`. `test.services.nixosConfig` can set the environment of the
`nix run` command for the test.

Run all tests:

```bash
nix build .#apps.<app-name>.test --print-build-logs
```

Run program test:

```bash
nix build .#apps.<app-name>.test-programs --print-build-logs
```

Run service test:

```bash
nix build .#apps.<app-name>.test-services-container --print-build-logs
nix build .#apps.<app-name>.test-services-nixos --print-build-logs
```

## Re-exporting packages

If exposing a package already in nixpkgs, consider re-exporting the package using the new [`build.builders.identity`](https://ngi.nixos.org/recipe/options?p=apps&p=pkgs&q=identity#pkgs.%3Cname%3E.build.builders.identity.enable). This will allow the application to be accessed under the `pkgs` attribute path (i.e. `pkgs.<app-name>`). To do this, outside of the `apps.<app-name>` attribute set, add the following block:

```nix
pkgs.<app-name> = {
  build.builders.identity = {
    enable = true;
    derivation = pkgs.pkgsOriginal.<app-name>;
  };
};
```

::: {note}
`pkgs.pkgsOriginal` will always provide packages from the original source of the `pkgs` attribute set (nixpkgs in almost in all cases).
This is to clearly differentiate between packages provided in the forge (in `recipes/pkgs`), and packages from the original `pkgs`.
:::

## Examples

Browse the
[example application recipes](https://github.com/ngi-nix/forge/tree/master/templates/provider/recipes/apps),
or create your own Forge project to try them out:

```bash
nix flake init --template github:ngi-nix/forge#provider
```
