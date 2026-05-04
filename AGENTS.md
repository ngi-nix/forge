# NGI Forge Recipe Generation Specification for LLMs

## Overview

This specification guides LLMs in generating NGI Forge recipes - declarative configuration files for building software packages and applications.

### Supported Project Types

**IMPORTANT:** NGI Forge currently supports the following types of projects:

1. **Python applications** - Projects with `pyproject.toml` or `setup.py` that provide CLI tools (use `pythonAppBuilder`)
2. **Python libraries** - Projects with `pyproject.toml` or `setup.py` meant to be imported by other packages (use `pythonPackageBuilder`)
3. **Go modules** - Projects with `go.mod` (use `goPackageBuilder`)
4. **Rust crates** - Projects with `Cargo.toml` (use `rustPackageBuilder`)
5. **CMake-based projects** - Projects with `CMakeLists.txt` (use `standardBuilder`)
6. **Autotools-based projects** - Projects with `configure` or `configure.ac` (use `standardBuilder`)
7. **Makefile-based projects** - Projects with standard `Makefile` targets (use `standardBuilder`)

## Recipe File Structure

### Location

- **Packages**: `recipes/packages/<package-name>/recipe.nix`
- **Apps**: `recipes/apps/<app-name>/recipe.nix`

### Basic Template

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Recipe fields go here
}
```

**Note**: The function parameters are REQUIRED and should always be included, even if not used.

### Accessing NGI Forge Packages

Other packages built by NGI Forge can be referenced in recipes using `rootConfig.packages`:

```nix
{
  # Reference another NGI Forge package
  packages.run = [
    rootConfig.packages.gdal  # Access gdal from NGI Forge
  ];
}
```

This follows the same pattern as accessing nixpkgs packages (e.g., `pkgs.sqlite`).

### Important: Git Tracking Required

**CRITICAL**: All new recipe files MUST be added to git before they can be used by the Nix flake system.

After creating a new recipe file, you must run:

```bash
git add recipes/packages/<package-name>/recipe.nix
# or for apps:
git add recipes/apps/<app-name>/recipe.nix
```

The flake uses `import-tree` to automatically discover recipes, but it only sees files tracked by git. Without adding the file to git, the package will not be recognized and `nix build .#<package-name>` will fail with an error like:

```
error: flake does not provide attribute 'packages.x86_64-linux.<package-name>'
```

## Package Recipes

### Required Fields

```nix
{
  name = "package-name";           # String, lowercase with hyphens
  version = "1.0.0";               # String, semantic versioning
  description = "Short description of the package.";

  # Source: EXACTLY ONE of these must be defined
  source.git = "github:owner/repo/commit-or-tag";  # OR
  source.url = "https://...";
  source.hash = "sha256-...";      # Required with url, optional with git

  # Builder: EXACTLY ONE must be enabled
  build.standardBuilder.enable = true;      # OR
  build.pythonAppBuilder.enable = true;     # OR
  build.pythonPackageBuilder.enable = true; # OR
  build.goPackageBuilder.enable = true;     # OR
  build.rustPackageBuilder.enable = true;
}
```

### Optional but Recommended Fields

```nix
{
  homePage = "https://project-website.org";
  mainProgram = "executable-name";  # Main binary name for the package
}
```

## Builder Types

### 1. standardBuilder (Most Common)

**When to use**: Standard autotools/cmake/make-based projects

```nix
{
  build.standardBuilder = {
    enable = true;
    packages.build = [
      pkgs.cmake
      pkgs.pkg-config
    ];
    packages.run = [
      pkgs.openssl
      pkgs.zlib
    ];
    packages.check = [
      pkgs.cunit
    ];
  };
}
```

**Characteristics**:

- Automatic configure, build, install phases
- Follows standard build conventions
- Use for: C/C++ projects with configure scripts or CMake

### 2. pythonAppBuilder (Python Applications)

**When to use**: Python applications with pyproject.toml that provide executable programs

```nix
{
  build.pythonAppBuilder = {
    enable = true;
    packages = {
      build-system = [
        pkgs.python3Packages.setuptools
      ];
      dependencies = [
        pkgs.python3Packages.flask
        pkgs.python3Packages.requests
      ];
      optional-dependencies = {      # PEP-621 extras (optional)
        dev = [
          pkgs.python3Packages.pytest
        ];
      };
    };
    importsCheck = [ "myapp" ];      # Verify imports work (optional)
    relaxDeps = [ "flask" ];         # Remove version constraints (optional)
    disabledTests = [ "test_network" ]; # Skip specific tests (optional)
  };
}
```

**Characteristics**:

- Uses `buildPythonApplication` internally
- Creates standalone applications with entry points
- Prevents the package from being used as a dependency by other Python packages
- Use for: CLI tools, web applications, standalone Python programs

**Additional Options** (same as pythonPackageBuilder):

- **optional-dependencies**: PEP-621 optional dependency groups (extras)
  - Maps to nixpkgs: `optional-dependencies`
- **importsCheck**: List of modules to verify can be imported
  - Maps to nixpkgs: `pythonImportsCheck`
- **relaxDeps**: Remove version constraints from dependencies (list or true for all)
  - Maps to nixpkgs: `pythonRelaxDeps`
- **disabledTests**: Skip specific pytest test names
  - Maps to nixpkgs: `disabledTests`

### 3. pythonPackageBuilder (Python Libraries)

**When to use**: Python libraries/packages with pyproject.toml that other packages depend on

```nix
{
  build.pythonPackageBuilder = {
    enable = true;
    packages = {
      build-system = [
        pkgs.python3Packages.setuptools
      ];
      dependencies = [
        pkgs.python3Packages.numpy
        pkgs.python3Packages.attrs
      ];
      optional-dependencies = {      # PEP-621 extras (optional)
        dev = [
          pkgs.python3Packages.pytest
        ];
      };
    };
    importsCheck = [ "mylib" ];      # Verify imports work (optional)
    relaxDeps = [ "numpy" ];         # Remove version constraints (optional)
    disabledTests = [ "test_slow" ]; # Skip specific tests (optional)
  };
}
```

**Characteristics**:

- Uses `buildPythonPackage` internally
- Creates reusable Python libraries
- Can be used as dependencies by other Python packages
- Use for: Python libraries, frameworks, utility modules

**Additional Options**:

- **optional-dependencies**: PEP-621 optional dependency groups (extras)
  - Maps to nixpkgs: `optional-dependencies`
- **importsCheck**: List of modules to verify can be imported
  - Maps to nixpkgs: `pythonImportsCheck`
- **relaxDeps**: Remove version constraints from dependencies (list or true for all)
  - Maps to nixpkgs: `pythonRelaxDeps`
- **disabledTests**: Skip specific pytest test names
  - Maps to nixpkgs: `disabledTests`

**Note**: Use pkgs.python3Packages.* for Python dependencies

**Choosing between pythonAppBuilder and pythonPackageBuilder**:

- **pythonAppBuilder**: For programs meant to be run (`mypy`, `black`, `fio`)
- **pythonPackageBuilder**: For libraries meant to be imported (`requests`, `numpy`, `attrs`)

### 4. goPackageBuilder (Go Modules)

**When to use**: Go projects using Go modules

```nix
{
  build.goPackageBuilder = {
    enable = true;
    packages.build = [
      pkgs.pkg-config
    ];
    packages.run = [
      pkgs.openssl
    ];
    packages.check = [
      pkgs.gotestsum
    ];
    vendorHash = "sha256-...";
    ldflags = [ "-X main.version=1.0.0" ];
  };
}
```

**Characteristics**:

- Uses `buildGoModule` from nixpkgs
- Supports vendoring and proxy vendoring
- Can build multiple packages via `subPackages`

**Inputs options**:

- `packages.build`: Build-time tools (pkg-config, installShellFiles)
- `packages.run`: CGO dependencies (openssl, sqlite)
- `packages.check`: Test tools (gotestsum)

### 5. rustPackageBuilder (Rust Crates)

**When to use**: Rust projects with Cargo

```nix
{
  build.rustPackageBuilder = {
    enable = true;
    packages.build = [
      pkgs.pkg-config
      pkgs.rustPlatform.bindgenHook
    ];
    packages.run = [
      pkgs.openssl
      pkgs.sqlite
    ];
    packages.check = [
      pkgs.cargo-nextest
    ];
    cargoHash = "sha256-...";
    cargoBuildFlags = [ "--release" ];
  };
}
```

**Characteristics**:

- Uses `rustPlatform.buildRustPackage` from nixpkgs
- Supports cargo hash verification
- Handles native build inputs via bindgenHook for crates with C bindings

**Inputs options**:

- `packages.build`: Build-time tools (pkg-config, bindgenHook)
- `packages.run`: Runtime dependencies (openssl, sqlite, etc.)
- `packages.check`: Test tools (cargo-nextest)

## Source Configuration

### Git Sources

**Format**: `forge:owner/repository/revision`

```nix
source = {
  git = "github:torvalds/linux/v6.1";  # Tag
  git = "gitlab:group/project/abc123";  # Commit hash
  hash = "sha256-...";  # Optional but recommended
};
```

**Supported forges**: github, gitlab, codeberg, forgejo, gitea

**Git submodules**: Set `source.submodules = true` to fetch git submodules along with the repository.

### URL Sources

```nix
source = {
  url = "https://releases.example.com/package-1.0.0.tar.gz";
  url = "mirror://gnu/hello/hello-2.12.1.tar.gz";  # Nix mirrors
  hash = "sha256-...";  # REQUIRED
};
```

### Patches

Apply patch files to the source code before building:

```nix
source = {
  git = "github:owner/repo/v1.0.0";
  hash = "sha256-...";
  patches = [
    ./fix-build-issue.patch
    ./add-feature.patch
  ];
};
```

**Notes**:

- Patches are applied in the order specified
- Patch files must be relative paths (e.g., `./fix.patch`)
- Patches are applied using the standard `patch` command
- Works with all source types (git, url, path)

## Test Configuration

```nix
test = {
  packages = [ pkgs.curl ];  # Additional test dependencies
  script = ''
    # Test commands
    $out/bin/program --version
    $out/bin/program --help
  '';
};
```

**Best practices**:

- Test main functionality
- Verify version output
- Check help/usage works
- Keep tests fast (< 10 seconds)

## Development Environment

```nix
development = {
  packages = [ pkgs.gdb pkgs.valgrind ];  # Dev tools
  shellHook = ''
    echo "Development environment ready"
    echo "Source code: clone from ${source.git}"
  '';
};
```

## Advanced: extraAttrs

For expert-level customization:

```nix
build.extraAttrs = {
  preConfigure = ''
    export HOME=$(mktemp -d)
  '';
  postInstall = ''
    wrapProgram $out/bin/program \
      --set SOME_VAR value
  '';
  enableParallelBuilding = true;
};
```

**Common use cases**:

- `preConfigure`: Set environment before configure
- `postInstall`: Wrap binaries, add extra files
- `patches`: Apply source patches
- `configureFlags`: Pass flags to configure script

## Application Recipes

### Structure

```nix
{
  name = "app-name";
  displayName = "Human Readable Name";  # Optional: defaults to name if not set
  description = "Application description.";
  usage = ''
    Usage instructions in markdown format.

    Supports markdown formatting, code blocks, etc.
  '';  # Optional but highly recommended

  icon = ./icon.svg;  # Optional: Path to SVG icon file

  # Optional: Services configuration (portable services)
  services = { ... };

  # Enable output types (at least one must be enabled):
  programs = { ... };    # Shell bundle
  container = { ... };   # OCI container image
  nixos = { ... };       # NixOS VM
}
```

### Application Icon

Apps can optionally specify a custom icon in SVG format. When creating app recipes, LLMs should:

1. **Search for existing icons** in the source repository:
   - Look for files named: `logo.svg`, `icon.svg`, `app-icon.svg`, or project-specific names
   - Check common directories: root, `assets/`, `resources/`, `icons/`, `images/`, `docs/`, `.github/`
   - Only use icons in SVG format

2. **Icon requirements:**
   - Must be in SVG format
   - Should be simple and recognizable at small sizes (48x48px minimum)
   - Will be displayed in the app list and detail views

3. **If icon found:**
   ```nix
   icon = ./icon.svg;  # Path relative to recipe.nix
   ```
   Copy the icon file to the recipe directory.

4. **If no icon found:**
   - Omit the `icon` field
   - A default icon will be used automatically

**Example with icon:**

```nix
{
  name = "my-app";
  displayName = "My Application";
  description = "My application";
  icon = ./logo.svg;  # Found in repository root

  programs = {
    runtimes.shell.enable = true;
  };
  # ... rest of configuration
}
```

**IMPORTANT:** Apps are always included in the packages output. However, individual outputs (programs bundle, container, VM) are only generated when their respective `enable` option is set to `true`. If all three options are disabled, the app package will be available but will have no functional outputs.

### Services (Portable Services)

Services define processes that run within the application. They can be used across all output types (container, VM, etc.):

```nix
services = {
  my-service = {
    command = rootConfig.packages.my-package;  # Package or string
    argv = [ "--port" "8080" ];        # Additional arguments
    environment = {                     # Environment variables
      DATABASE_URL = "postgresql://localhost/db";
      LOG_LEVEL = "info";
    };
  };

  another-service = {
    command = "python";
    argv = [ "-m" "http.server" "8000" ];
  };
};
```

### Programs (Shell Bundle)

Creates a shell bundle with all required packages available in PATH:

```nix
programs = {
  packages = [
    rootConfig.packages.my-package  # Reference packages from forge
    pkgs.curl
    pkgs.jq
  ];

  runtimes.shell = {
    enable = true; # Set to true to enable programs bundle output
  };
};
```

**Structure:**

- `programs.packages`: List of packages to include in the shell environment
- `programs.runtimes.shell.enable`: Enable shell environment

**Access:** `nix shell .#<app>` or `nix build .#<app>`

### Container (OCI Image)

Builds a single OCI-compliant container image:

```nix
container = {
  enable = true;  # Set to true to enable container image output
  tag = "latest";  # Optional, defaults to "latest"

  packages = [
    rootConfig.packages.my-package  # Packages to include in /bin
  ];

  # OCI image configuration
  # See: https://specs.opencontainers.org/image-spec/config/#properties
  extraConfig = {
    Cmd = [ "my-package" "--serve" ];  # Default command
    Env = [                             # Environment variables
      "PORT=8080"
      "LOG_LEVEL=info"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
    WorkingDir = "/app";
  };

  composeFile = ./compose.yaml;  # Optional: Docker Compose file
};
```

**Access:** `nix build .#<app>.container` to build the image script

**Note:** Services defined in the `services` section are automatically included in the container configuration.

### NixOS VM

Builds a complete NixOS virtual machine:

```nix
nixos = {
  enable = true;  # Set to true to enable VM output

  # NixOS system configuration
  # See: https://search.nixos.org/options
  extraConfig = {
    services.postgresql = {
      enable = true;
      enableTCPIP = true;
      authentication = ''
        local all all trust
        host all all 0.0.0.0/0 trust
      '';
    };

    services.nginx.enable = true;
  };

  # VM-specific settings
  vm = {
    cores = 4;           # Number of CPU cores (default: 4)
    memorySize = 2048;   # RAM in MiB (default: 2048)
    diskSize = 4096;     # Disk size in MiB (default: 4096)
    forwardPorts = [     # Port forwarding (HOST:GUEST)
      "8080:80"
      "5432:5432"
    ];
  };
};
```

**Access:** `nix build .#<app>.vm` then run `./result/bin/run-*-vm`

**Note:** Services defined in the `services` section are automatically configured as systemd services in the VM.

### Output Control

Each app output type can be independently enabled or disabled:

- **programs.runtimes.shell.enable**: Controls the shell bundle (accessed via `nix shell .#<app>`)
- **container.enable**: Controls the container image (accessed via `nix build .#<app>.container`)
- **nixos.enable**: Controls the virtual machine (accessed via `nix build .#<app>.vm`)

**Complete example with all outputs:**

````nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "python-web-app";
  displayName = "Python Web Example";
  description = "Simple web application with database backend.";
  usage = ''
    This is a simple example app which provides a web API.

    * Initialize database
    ```
    curl -X POST localhost:5000/init
    ```

    * Add a new user
    ```
    curl -X POST --header "Content-Type: application/json" \
      --data '{"name":"username"}' localhost:5000/users
    ```
  '';

  # Define the web service
  services.python-web = {
    command = rootConfig.packages.python-web;
    argv = [ "--host" "0.0.0.0" ];
    environment = {
      FLASK_ENV = "production";
    };
  };

  # Shell bundle with additional tools
  programs = {
    packages = [
      rootConfig.packages.python-web
      pkgs.curl
      pkgs.postgresql
    ];

    runtimes.shell = {
      enable = true;
    };
  };

  # Container image
  container = {
    enable = true;
    tag = "latest";
    packages = [ rootConfig.packages.python-web ];
    extraConfig = {
      Env = [ "PORT=5000" ];
      ExposedPorts = { "5000/tcp" = { }; };
    };
    composeFile = ./compose.yaml;
  };

  # VM with PostgreSQL
  nixos = {
    enable = true;
    extraConfig = {
      services.postgresql = {
        enable = true;
        enableTCPIP = true;
      };
    };
    vm.forwardPorts = [ "5000:5000" ];
  };
}
````

## LLM Generation Guidelines

### 1. Information Gathering

Before generating a recipe, determine:

- **Software name and version**
- **Programming language/build system**
- **Source location** (GitHub URL, release tarball)
- **Build dependencies** (libraries, tools)
- **Runtime dependencies**
- **Main executable name**

### 2. Builder Selection Logic

```
IF Python project with pyproject.toml:
  IF provides CLI tools/executables (has [project.scripts] or entry_points):
    → pythonAppBuilder
  ELSE IF library meant to be imported:
    → pythonPackageBuilder

ELSE IF has go.mod:
  → goPackageBuilder

ELSE IF has Cargo.toml:
  → rustPackageBuilder

ELSE IF has configure script OR uses CMake OR standard Makefile:
  → standardBuilder
  (Use build.extraAttrs for custom build configuration)
```

### 3. Dependency Resolution

- **Build tools**: cmake, pkg-config, autoconf → `packages.build`
- **Libraries**: openssl, zlib, curl → `packages.run`
- **Python packages**: Use `pkgs.python3Packages.*`
- **Unknown packages**: Use `pkgs.<package-name>`

### 4. Hash Determination

When hash is unknown:

```nix
source.hash = "";  # Leave empty initially
# Nix will error with correct hash, then update recipe
```

### 5. Validation Checklist

- [ ] Exactly one builder enabled (standardBuilder, pythonAppBuilder, pythonPackageBuilder, goPackageBuilder, or rustPackageBuilder)
- [ ] For Python projects: correct builder chosen (pythonAppBuilder for apps, pythonPackageBuilder for libraries)
- [ ] Source has git XOR url (not both)
- [ ] Hash present for URL sources
- [ ] name is lowercase-with-hyphens
- [ ] mainProgram matches actual executable
- [ ] Test script tests main functionality
- [ ] No hardcoded /nix/store paths

## Common Patterns

### Pattern 1: Simple GitHub Project

```nix
{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "ripgrep";
  version = "14.0.0";
  description = "Fast line-oriented search tool.";
  homePage = "https://github.com/BurntSushi/ripgrep";
  mainProgram = "rg";

  source = {
    git = "github:BurntSushi/ripgrep/14.0.0";
    hash = "sha256-...";
  };

  build.standardBuilder = {
    enable = true;
    packages.build = [
      pkgs.rustc
      pkgs.cargo
    ];
    packages.run = [ ];
  };

  test.script = ''
    rg --version | grep "14.0.0"
  '';
}
```

### Pattern 2: C Project with Dependencies

```nix
{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "nginx";
  version = "1.24.0";
  description = "HTTP and reverse proxy server.";
  homePage = "https://nginx.org";
  mainProgram = "nginx";

  source = {
    url = "https://nginx.org/download/nginx-1.24.0.tar.gz";
    hash = "sha256-...";
  };

  build.standardBuilder = {
    enable = true;
    packages.build = [
      pkgs.which
    ];
    packages.run = [
      pkgs.openssl
      pkgs.pcre
      pkgs.zlib
    ];
  };

  test.script = ''
    nginx -v 2>&1 | grep "1.24.0"
  '';
}
```

### Pattern 3: Python Application

```nix
{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "mypy";
  version = "1.7.0";
  description = "Static type checker for Python.";
  homePage = "https://mypy-lang.org";
  mainProgram = "mypy";

  source = {
    git = "github:python/mypy/v1.7.0";
    hash = "sha256-...";
  };

  build.pythonAppBuilder = {
    enable = true;
    packages.build-system = [
      pkgs.python3Packages.setuptools
    ];
    packages.dependencies = [
      pkgs.python3Packages.typing-extensions
      pkgs.python3Packages.mypy-extensions
    ];
  };

  test.script = ''
    mypy --version | grep "1.7.0"
  '';
}
```

### Pattern 4: Python Library

```nix
{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "requests";
  version = "2.31.0";
  description = "Python HTTP library for humans.";
  homePage = "https://requests.readthedocs.io";
  mainProgram = "";  # No main program for libraries

  source = {
    git = "github:psf/requests/v2.31.0";
    hash = "sha256-...";
  };

  build.pythonPackageBuilder = {
    enable = true;
    packages.build-system = [
      pkgs.python3Packages.setuptools
    ];
    packages.dependencies = [
      pkgs.python3Packages.charset-normalizer
      pkgs.python3Packages.idna
      pkgs.python3Packages.urllib3
      pkgs.python3Packages.certifi
    ];
  };

  test.script = ''
    python -c "import requests; print(requests.__version__)" | grep "2.31.0"
  '';
}
```

## Error Handling

### Common Issues and Solutions

**Issue**: "source.git or source.url must be defined"

- **Solution**: Ensure exactly one source method is specified

**Issue**: "Only one builder can be enabled"

- **Solution**: Set only one `build.*.enable = true`

**Issue**: Hash mismatch

- **Solution**: Update hash with value from error message

**Issue**: Missing dependency

- **Solution**: Add to packages.build or packages.run

## Naming Conventions

- **Package names**: lowercase-with-hyphens (e.g., `my-package`)
- **Versions**: Semantic versioning (e.g., `1.2.3`, `2024-01-15`)
- **File paths**: Use `./` for relative paths (e.g., `./compose.yaml`)
- **Programs**: Binary name, not display name (e.g., `rg` not `ripgrep`)

## Summary for LLMs

When generating a NGI Forge recipe:

1. **Identify** the software and gather information
2. **Choose** appropriate builder based on build system
3. **Define** source (git or url with hash)
4. **List** all dependencies in correct categories
5. **Write** meaningful test script
6. **Validate** against checklist
7. **Format** consistently with examples

The goal is a **declarative, reproducible, and testable** package definition that abstracts Nix complexity while maintaining flexibility.

---

# Repository Analysis Process for Creating Recipes

This section provides a systematic process for analyzing third-party software repositories and creating NGI Forge recipes.

## Step-by-Step Repository Analysis

### Step 1: Identify Build System

Check for these files in the repository (in order of priority):

1. **Python Projects**
   - `pyproject.toml` → Check for `[project.scripts]` or entry points
     - Has CLI tools/executables → Use `pythonAppBuilder`
     - Library/module only → Use `pythonPackageBuilder`
   - `setup.py` → Check for `entry_points` or `console_scripts`
     - Has CLI tools/executables → Use `pythonAppBuilder`
     - Library/module only → Use `pythonPackageBuilder`

2. **CMake Projects**
   - `CMakeLists.txt` → Use `standardBuilder`

3. **Autotools Projects**
   - `configure.ac` or `configure` → Use `standardBuilder`

4. **Makefile Projects**
   - `Makefile` with standard targets (all, install, clean) → Use `standardBuilder`

### Step 2: Check Repository Structure

**Critical checks:**

- [ ] **Is the build file in the root directory?** (most common case)
  - If YES: No special configuration needed
  - If NO: Determine the subdirectory

- [ ] **Is the code in a subdirectory?**
  - Example: `geodiff/geodiff/CMakeLists.txt` (build file is in `geodiff/` subdirectory)
  - Solution: Set `build.extraAttrs.sourceRoot = "source/<subdir>";`

- [ ] **Is this a monorepo with multiple projects?**
  - Identify the correct subdirectory for the package you want to build

### Step 3: Check for Git Submodules

Check for submodules:

```bash
# Look for .gitmodules file in the repository
# Check repository structure for empty/missing subdirectories
```

**If git submodules exist**, enable submodule fetching:

```nix
source = {
  git = "github:owner/repo/v1.0.0";
  hash = "sha256-...";
  submodules = true;  # Fetch git submodules
};
```

### Step 4: Identify Dependencies

**Where to look:**

1. **CMake projects** (`CMakeLists.txt`):
   - `find_package(<PackageName>)` → Required dependency
   - `pkg_check_modules(<VAR> <package>)` → pkg-config dependency
   - Look for library names and map to nixpkgs

2. **Python projects** (`pyproject.toml`, `setup.py`, `requirements.txt`):
   - `[project.dependencies]` section in pyproject.toml
   - `install_requires` in setup.py
   - Map to `pkgs.python3Packages.<name>`

3. **Autotools projects** (`configure.ac`):
   - `PKG_CHECK_MODULES([VAR], [package])` → pkg-config dependency
   - `AC_CHECK_LIB([library], [function])` → Library dependency

4. **README.md, INSTALL.md, or documentation**:
   - Often lists required dependencies for building

5. **CI Configuration** (`.github/workflows/`, `.gitlab-ci.yml`):
   - Shows what gets installed before building
   - Reveals build and test dependencies

**Dependency categories:**

- **Build tools** (cmake, pkg-config, autoconf, meson, ninja) → `packages.build`
- **Libraries** (sqlite, gdal, openssl, zlib, postgresql) → `packages.run`
- **Test Tools** (cunit, pytest) → `packages.check`
- **Python packages** → `pkgs.python3Packages.<name>` in dependencies

### Step 5: Check for External/Vendored Dependencies

**Warning signs of problematic external downloads:**

- `external/` or `third_party/` directories (may be git submodules)
- `ExternalProject_Add()` in CMakeLists.txt (downloads during build - **PROBLEM!**)
- `FetchContent` in CMake (downloads during build - **PROBLEM!**)
- Download scripts in build files

**If external downloads occur during build:**

Nix builds in a sandbox without network access. You must:

1. **Option 1:** Disable with CMake/build flags
   ```nix
   build.extraAttrs = {
     cmakeFlags = [ "-DUSE_EXTERNAL_LIBS=OFF" ];
   };
   ```

2. **Option 2:** Provide dependencies via nativeBuildInputs
   ```nix
   packages.build = [ pkgs.somelib ];
   ```

3. **Option 3:** Patch build files to remove download steps
   ```nix
   build.extraAttrs = {
     postPatch = ''
       substituteInPlace CMakeLists.txt \
         --replace-fail "ExternalProject_Add" "# ExternalProject_Add"
     '';
   };
   ```

### Step 6: Find the Main Executable

**Where to look:**

- `bin/` directory in source code
- CMake: `add_executable(<name> ...)` in CMakeLists.txt
- Python: `[project.scripts]` in pyproject.toml or `entry_points` in setup.py
- README.md usage examples (e.g., `$ geodiff --help`)

**Set in recipe:**

```nix
mainProgram = "executable-name";  # Just the binary name, not the path
```

### Step 7: Identify Latest Version

- Check GitHub releases page for latest stable release
- Prefer released versions over git commit hashes
- Use version tags (e.g., `v1.2.3` or `1.2.3`)

### Step 8: Identify Tests

**Where to look:**

- `test/` or `tests/` directory
- CMake: `enable_testing()`, `add_test()`, or `BUILD_TESTING` option
- Python: `pytest`, `unittest`, test files matching `test_*.py`
- CI configuration shows test commands

**For recipe test.script:**

- **Minimum:** `--version` and `--help` flags
- **Better:** Simple import test (Python), basic functional test
- **Keep fast:** Tests should complete in < 10 seconds

## Common Build Issues and Solutions

### Issue 1: "CMakeLists.txt not found"

**Error message:**

```
CMake Error: The source directory does not appear to contain CMakeLists.txt
```

**Diagnosis:** Build files are in a subdirectory, not the root.

**Solution:**

```nix
build.extraAttrs = {
  sourceRoot = "source/<subdirectory>";
};
```

**Example:**

```nix
build.extraAttrs = {
  sourceRoot = "source/geodiff";  # For geodiff/geodiff/CMakeLists.txt
};
```

### Issue 2: "Cannot download during build"

**Error message:**

```
CMake Error at CMakeLists.txt:104 (INCLUDE):
  INCLUDE could not find requested file:
    /build/source/build/external/libgpkg-.../UseTLS.cmake
```

**Diagnosis:**

- CMake tries to download dependencies with `ExternalProject_Add()` or `FetchContent`
- Git submodules not fetched
- Build downloads external resources

**Solutions:**

1. **Disable downloads via CMake flags:**
   ```nix
   build.extraAttrs = {
     cmakeFlags = [ "-DUSE_SYSTEM_LIBS=ON" "-DENABLE_EXTERNAL_DOWNLOAD=OFF" ];
   };
   ```

2. **Provide missing dependencies:**
   ```nix
   packages.run = [ pkgs.libgpkg ];  # If available in nixpkgs
   ```

3. **Patch CMakeLists.txt:**
   ```nix
   build.extraAttrs = {
     postPatch = ''
       substituteInPlace CMakeLists.txt \
         --replace-fail "include(ExternalProject)" ""
     '';
   };
   ```

### Issue 3: "Python dependency version mismatch"

**Error message:**

```
ERROR Missing dependencies:
  cython~=3.0.2
```

**Diagnosis:** Python package requires specific version, but nixpkgs has different version.

**Solution:** Relax version constraint by patching pyproject.toml:

```nix
build.extraAttrs = {
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "cython~=3.0.2" "cython"
  '';
};
```

### Issue 4: "Missing Python runtime dependencies"

**Error message:**

```
Checking runtime dependencies for package.whl
  - attrs not installed
  - click not installed
```

**Diagnosis:** Python package has runtime dependencies not listed in recipe.

**Solution:** Add missing packages to dependencies:

```nix
build.pythonAppBuilder = {
  packages.dependencies = [
    pkgs.python3Packages.attrs
    pkgs.python3Packages.click
    # ... other dependencies
  ];
};
```

### Issue 5: "Tests enabled but fail or unwanted"

**Diagnosis:** Build system enables tests by default, but they fail or slow down build.

**Solutions:**

For CMake:

```nix
build.extraAttrs = {
  cmakeFlags = [ "-DENABLE_TESTS=OFF" "-DBUILD_TESTING=OFF" ];
};
```

For Meson:

```nix
build.extraAttrs = {
  mesonFlags = [ "-Dtests=false" ];
};
```

For Autotools:

```nix
build.extraAttrs = {
  configureFlags = [ "--disable-tests" ];
};
```

## Builder Selection Decision Tree

```
START: What type of project is this?

├─ Has pyproject.toml or setup.py?
│  └─ YES → Python Project
│     ├─ Check pyproject.toml for [project.scripts] or setup.py for entry_points
│     ├─ Has executable entry points?
│     │  ├─ YES → Use pythonAppBuilder (CLI tools, applications)
│     │  │     ├─ packages.build-system: setuptools, cython, etc.
│     │  │     └─ packages.dependencies: runtime Python packages
│     │  └─ NO → Use pythonPackageBuilder (libraries, modules)
│     │        ├─ packages.build-system: setuptools, cython, etc.
│     │        └─ packages.dependencies: runtime Python packages
│
├─ Has go.mod?
│  └─ YES → Use goPackageBuilder
│     ├─ packages.build: build-time tools (pkg-config)
│     ├─ packages.run: CGO dependencies (openssl, sqlite)
│     └─ vendorHash: hash of Go module dependencies
│
├─ Has Cargo.toml?
│  └─ YES → Use rustPackageBuilder
│     ├─ packages.build: build-time tools (pkg-config, bindgenHook)
│     ├─ packages.run: runtime libraries (openssl, sqlite)
│     └─ cargoHash: hash of Cargo.lock
│
├─ Has CMakeLists.txt?
│  └─ YES → Use standardBuilder
│     ├─ packages.build: cmake, pkg-config
│     └─ packages.run: libraries (sqlite, gdal, etc.)
│
├─ Has configure or configure.ac?
│  └─ YES → Use standardBuilder (Autotools)
│     ├─ packages.build: autoconf, automake, libtool, pkg-config
│     └─ packages.run: libraries
│
└─ Has Makefile with standard targets?
   └─ YES → Use standardBuilder
      ├─ Check for: all, install, clean targets
      ├─ packages.build: make, pkg-config
      └─ packages.run: libraries
      └─ For custom configuration: use build.extraAttrs
```

## Common Dependencies Mapping

### C/C++ Libraries

| If build system looks for | Nix package to add |
| ------------------------- | ------------------ |
| SQLite, sqlite3, sqlite   | `pkgs.sqlite`      |
| GDAL, gdal                | `pkgs.gdal`        |
| PostgreSQL, libpq, pq     | `pkgs.postgresql`  |
| OpenSSL, ssl              | `pkgs.openssl`     |
| CURL, curl, libcurl       | `pkgs.curl`        |
| zlib, z                   | `pkgs.zlib`        |
| Boost, boost              | `pkgs.boost`       |
| GEOS, geos                | `pkgs.geos`        |
| PROJ, proj                | `pkgs.proj`        |
| libxml2, xml2             | `pkgs.libxml2`     |
| expat                     | `pkgs.expat`       |

### Python Packages

| If pyproject.toml/requirements has | Nix package to add                        |
| ---------------------------------- | ----------------------------------------- |
| click                              | `pkgs.python3Packages.click`              |
| requests                           | `pkgs.python3Packages.requests`           |
| numpy                              | `pkgs.python3Packages.numpy`              |
| attrs                              | `pkgs.python3Packages.attrs`              |
| certifi                            | `pkgs.python3Packages.certifi`            |
| setuptools                         | `pkgs.python3Packages.setuptools`         |
| cython                             | `pkgs.python3Packages.cython`             |
| wheel                              | `pkgs.python3Packages.wheel`              |
| pytest                             | `pkgs.python3Packages.pytest` (test only) |

### Build Tools (always in packages.build)

- `pkgs.cmake` - CMake build system
- `pkgs.pkg-config` - Finding library dependencies
- `pkgs.meson` - Meson build system
- `pkgs.ninja` - Ninja build tool
- `pkgs.autoconf` - Autotools
- `pkgs.automake` - Autotools
- `pkgs.libtool` - Autotools

## Recommended LLM Workflow

When asked to create a NGI Forge recipe from a git repository, follow this workflow:

### Phase 1: Research & Analysis

**Use the Task/Plan agent to gather information:**

1. Fetch and read repository README.md
2. Identify build system (check for CMakeLists.txt, pyproject.toml, etc.)
3. Check repository structure (is build file in root or subdirectory?)
4. Identify latest stable version from GitHub releases
5. List dependencies from build files and documentation
6. Find main executable/program name
7. Check for tests

**Output from this phase:** Comprehensive summary with all required information.

### Phase 2: Create Initial Recipe

1. Create package directory: `mkdir -p recipes/packages/<name>`
2. Write `recipe.nix` with:
   - Basic metadata (name, version, description, homePage, mainProgram)
   - Appropriate builder (pythonAppBuilder, pythonPackageBuilder, or standardBuilder)
   - `source.hash = ""` (leave empty initially)
   - Initial dependencies based on research
   - Basic test script (at minimum: `--help` and `--version`)

### Phase 3: Add to Git (CRITICAL!)

```bash
git add recipes/packages/<name>/recipe.nix
```

**Without this step, the package will not be recognized by the flake!**

### Phase 4: Iterative Build & Fix

1. **First build attempt:**
   ```bash
   nix build .#<package> -L
   ```

2. **Get correct hash:**
   - Build will fail with hash mismatch
   - Update `source.hash` with the correct value from error message

3. **Rebuild and fix errors iteratively:**
   ```bash
   nix build .#<package> -L
   ```

   Common fixes needed:
   - Add missing dependencies to `packages.build` or `packages.run`
   - Set `sourceRoot` if CMakeLists.txt not in root
   - Patch build files to remove external downloads
   - Relax Python version constraints
   - Disable unwanted tests

4. **Repeat until build succeeds**

### Phase 5: Test & Verify

1. Run package tests:
   ```bash
   nix build .#<package>.test -L
   ```

2. Verify tests pass

3. Manual verification (optional):
   ```bash
   ./result/bin/<program> --version
   ./result/bin/<program> --help
   ```

## Annotated Example: Complex Project (geodiff)

This example demonstrates a complex CMake project with subdirectory structure:

```nix
{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "geodiff";
  version = "2.0.4";
  description = "Library for handling diffs for geospatial data (GeoPackage and PostGIS).";
  homePage = "https://merginmaps.com";
  mainProgram = "geodiff";

  source = {
    git = "github:MerginMaps/geodiff/2.0.4";
    hash = "sha256-STWoSnBDl3K3F9SeXGvTy8TzZSAP6rZh3ebfMqdT/w0=";
  };

  build.standardBuilder = {
    enable = true;
    packages = {
      # Build tools needed during compilation
      build = [
        pkgs.cmake        # CMake build system
        pkgs.pkg-config   # For finding SQLite
      ];
      # Libraries needed at runtime
      run = [
        pkgs.sqlite       # Required dependency
      ];
    };
  };

  build.extraAttrs = {
    # CMakeLists.txt is in geodiff/geodiff/, not the root directory
    # Repository structure: geodiff/geodiff/CMakeLists.txt
    sourceRoot = "source/geodiff";

    # Optional: Override CMake configuration flags
    # cmakeFlags = [ "-DWITH_POSTGRESQL=OFF" ];

    # Optional: Disable tests if they fail or are slow
    # cmakeFlags = [ "-DENABLE_TESTS=OFF" ];
  };

  test.script = ''
    # Minimum viable tests
    geodiff --help
    geodiff --version
  '';
}
```

**Key points in this example:**

1. **sourceRoot**: Required because CMakeLists.txt is in `geodiff/` subdirectory
2. **cmake and pkg-config**: In `packages.build` because they're build-time tools
3. **sqlite**: In `packages.run` because it's a runtime dependency
4. **Test script**: Simple verification that the binary works

## Annotated Example: Python Project (fiona)

This example demonstrates a Python project with complex dependencies:

```nix
{
  rootConfig,
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "fiona";
  version = "1.10.1";
  description = "Python library for reading and writing vector geospatial data files.";
  homePage = "https://fiona.readthedocs.io";
  mainProgram = "fio";

  source = {
    git = "github:Toblerity/Fiona/1.10.1";
    hash = "sha256-5NN6PBh+6HS9OCc9eC2TcBvkcwtI4DV8qXnz4tlaMXc=";
  };

  build.pythonAppBuilder = {
    enable = true;
    packages = {
      # Python build system packages
      build-system = [
        pkgs.python3Packages.setuptools
        pkgs.python3Packages.cython
        pkgs.gdal  # GDAL also needed at build time for gdal-config
      ];
      # Python runtime dependencies
      dependencies = [
        pkgs.python3Packages.attrs
        pkgs.python3Packages.certifi
        pkgs.python3Packages.click
        pkgs.python3Packages.click-plugins
        pkgs.python3Packages.cligj
        pkgs.python3Packages.cython
        pkgs.gdal  # GDAL needed at runtime
      ];
    };
  };

  build.extraAttrs = {
    # Relax Cython version constraint from ~=3.0.2 to accept any version
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail "cython~=3.0.2" cython
    '';
  };

  test.script = ''
    # Test both Python import and CLI tool
    python -c "import fiona; print(fiona.__version__)"
    fio --version
  '';
}
```

**Key points in this example:**

1. **pythonAppBuilder**: Used for Python applications with CLI tools (fio command)
2. **GDAL in both build-system and dependencies**: Needed at build time (for `gdal-config`) and runtime
3. **postPatch**: Relaxes strict version constraint that would otherwise fail
4. **Test script**: Tests both the Python module import and CLI tool

**Note**: If this were a library without the `fio` CLI tool, use `pythonPackageBuilder` instead.

## Quick Reference Checklist

Before creating a recipe, gather this information:

- [ ] Project name (lowercase-with-hyphens)
- [ ] Latest stable version
- [ ] Build system type (Python app/library/CMake/Autotools/Makefile)
- [ ] For Python: Does it provide CLI tools or is it a library?
- [ ] Main executable name (if applicable)
- [ ] Homepage URL
- [ ] Build dependencies (libraries, tools)
- [ ] Runtime dependencies
- [ ] Repository structure (root or subdirectory?)
- [ ] Git submodules present? (if yes, set `source.submodules = true`)
- [ ] Test commands available?

During recipe creation:

- [ ] Choose correct builder (standardBuilder, pythonAppBuilder, pythonPackageBuilder, goPackageBuilder, or rustPackageBuilder)
- [ ] Leave source.hash empty initially
- [ ] Add recipe to git BEFORE building
- [ ] Build to get correct hash
- [ ] Fix errors iteratively
- [ ] Verify tests pass
