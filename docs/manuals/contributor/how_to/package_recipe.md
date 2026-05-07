# How to create a package recipe

Package recipes are located in `recipes/packages/<package>/recipe.nix`.

## Step 1: Investigate the package

Before writing a recipe, please dedicate some time to understant the software
and to gather the basic information from the package's source repository:

**Metadata**
- Package name, latest stable version, homepage URL, license
- Main executable name

**Language and build system**

Look for these files in the repository root:

| File | Build system |
|------|-------------|
| `pyproject.toml` or `setup.py` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `CMakeLists.txt` | CMake (C/C++) |
| `configure.ac` or `configure` | Autotools (C/C++) |
| `Makefile` | Make (C/C++) |

**Dependencies** — look in:
- `CMakeLists.txt`: `find_package()`, `pkg_check_modules()`
- `pyproject.toml` / `setup.py`: `[project.dependencies]`, `install_requires`
- `configure.ac`: `PKG_CHECK_MODULES`, `AC_CHECK_LIB`
- `README.md`, `INSTALL.md`: listed prerequisites
- CI config (`.github/workflows/`, `.gitlab-ci.yml`): packages installed before build

**Repository structure**
- Are build files in the repository root or a subdirectory?
- Are there git submodules (`.gitmodules` file)?
- Does the build download anything at build time. Nix builds run without network
  access - these must be patched out or disabled via build flags.

## Step 2: Write the recipe

Start with the generic metadata, then add the source, then enable the chosen
builder.

### Generic metadata

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "package-name";       # lowercase with hyphens
  version = "1.0.0";
  description = "Short description of the package.";
  homePage = "https://project-website.org";
  mainProgram = "executable-name";
}
```

### Source

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

### Builder

Enable exactly one builder and configure it as needed.

| Condition | Builder |
|-----------|---------|
| Python with CLI tools (`[project.scripts]` or `entry_points`) | `pythonAppBuilder` |
| Python library (no executables) | `pythonPackageBuilder` |
| Go (`go.mod`) | `goPackageBuilder` |
| Rust (`Cargo.toml`) | `rustPackageBuilder` |
| CMake, Autotools, or Makefile | `standardBuilder` |

Also, you need to add some dependencies using `packages.build` or `packages.run`.

```nix
  build.standardBuilder.enable = true;

  # OR

  # build.pythonAppBuilder.enable = true;
  # build.pythonPackageBuilder.enable = true;
  # build.goPackageBuilder.enable = true;
  # build.rustPackageBuilder.enable = true;
```

::: {note}
For full details on each builder's options, see the
[NGI Forge Options reference](https://ngi-nix.github.io/forge/recipe/options).
:::


Add the recipe to Git:

```bash
git add recipes/packages/<package>/recipe.nix
```

Now, it is the time to try to build the package:

```bash
  nix build .#<package> --print-build-logs
```

::: {important}
Nix will fail during the first build due to missing hash. Update `source.hash`
with the value from the error output, then try to build once again !
:::

#### Debug build

To troubleshoot build failures, enable debug mode to launch interactive build
environment:

```nix
  build.debug = true;
```

and launch debug build and follow the instructions

```bash
  mkdir dev && cd dev
  nix develop .#<package>
```

### Tests

Add a test script to verify the package works correctly:

```nix
  test.script = ''
    program --help | grep "Usage: program"
  '';
```

Run test:

```bash
  nix build .#<package>.test --print-build-logs
```
