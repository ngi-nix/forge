# How to create a package recipe

::: {important}
For the list of all available configuration options for package recipes visit
the
[package options reference](https://ngi-nix.github.io/forge/recipe/options?s=packages).
:::

Before writing a recipe, please spend some time to understand the software
and gather the basic information from the package's source code repository:

**Metadata**

- Package name, description
- Latest stable version
- Homepage URL
- License
- Main executable name

**Language and build system**

Look for these files in the repository root:

| File                           | Build system      |
| ------------------------------ | ----------------- |
| `configure.ac` or `configure`  | Autotools (C/C++) |
| `CMakeLists.txt`               | CMake (C/C++)     |
| `go.mod`                       | Go                |
| `Makefile`                     | Make (C/C++)      |
| `pyproject.toml` or `setup.py` | Python            |
| `Cargo.toml`                   | Rust              |

**Dependencies** — look in:

- `CMakeLists.txt`: `find_package()`, `pkg_check_modules()`
- `configure.ac`: `PKG_CHECK_MODULES`, `AC_CHECK_LIB`
- `pyproject.toml` / `setup.py`: `[project.dependencies]`, `install_requires`
- `README.md`, `INSTALL.md`: listed prerequisites
- CI config (`.github/workflows/`, `.gitlab-ci.yml`): packages installed before build

**Repository structure**

- Are build files in the repository root or a subdirectory?
- Are there git submodules (`.gitmodules` file)?
- Does the build download anything at build time? Nix builds run without network
  access - these must be patched out or disabled via build flags.

## Recipe file

Create the package recipe directory and recipe file:

```bash
mkdir recipes/packages/<package-name>
touch recipes/packages/<package-name>/recipe.nix
```

Add the recipe file to Git:

```bash
git add recipes/packages/<package-name>/recipe.nix
```

::: {important}
Nix can only see recipe files tracked by Git. If the file is not added
to Git, the package will not be recognized.
:::

## Metadata

Start the package recipe with the following content:

```nix
{
  pkgs,
  ...
}:

{
  packages.my-package = {        # lowercase with hyphens
    version = "1.0.0";           # latest released version
    description = "Short description of the package.";
    homePage = "https://project-website.org";
    mainProgram = "executable-name";
    license = lib.licenses.gpl3Only;
  };

  # More configuration to be added here.
  # ...
}
```

::: {note}
Use the following command to get the list of all available licenses:

```bash
nix eval nixpkgs#lib.licenses --json | jq
```

:::

## Source

Add a `source` block pointing to the upstream release. Leave `hash` empty for
now:

```nix
source = {
  git = "github:owner/repo/v1.0.0";
  hash = "";  # fill in after first build
};
```

For tarball releases use `source.url`.

If the repository uses git submodules, add `source.submodules = true`.

## Builder

Enable exactly one builder and configure it as needed.

| Condition                                                     | Builder                |
| ------------------------------------------------------------- | ---------------------- |
| CMake, Autotools, or Makefile                                 | `standardBuilder`      |
| Go                                                            | `goPackageBuilder`     |
| Python with CLI tools (`[project.scripts]` or `entry_points`) | `pythonAppBuilder`     |
| Python library (no executables)                               | `pythonPackageBuilder` |
| Rust                                                          | `rustPackageBuilder`   |

Also, add dependencies using `packages.build`, `packages.run` or
`packages.check` options.

```nix
build.standardBuilder = {
  enable = true;

  # build-time dependencies
  packages.build = [
    pkgs.bison
    pkgs.boost
  ];

  # run-time dependencies
  packages.run = [
    pkgs.zlib
  ];
}
```

Run the first build:

```bash
nix build .#<package-name> --print-build-logs
```

Nix will fail during the first build due to a missing source hash. Update
`source.hash` with the value from the error output, then launch the build once
again.

### Troubleshooting

To troubleshoot build failures, enable _debug_ mode to enter an interactive
build environment:

```nix
build.debug = true;
```

Then launch the interactive build and follow the on-screen instructions. Press
Ctrl-C to drop into a shell and start investigating.

```bash
mkdir dev && cd dev
nix develop .#<package-name>
```

## Tests

Add a test script to verify that package works correctly:

```nix
test.script = ''
  program --help | grep "Usage: program"
'';
```

Run test:

```bash
nix build .#<package-name>.test --print-build-logs
```
