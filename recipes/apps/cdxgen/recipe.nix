{
  config,
  pkgs,
  lib,
  ...
}:

let
  app = config.apps.cdxgen;
in

{
  pkgs.cdxgen = {
    build.identityBuilder = {
      enable = true;
      # TODO: replace with `pkgs.pkgsOriginal.cdxgen` after:
      # https://github.com/NixOS/nixpkgs/pull/558435
      derivation = pkgs.callPackage ./_cdxgen.nix { };
    };
  };

  apps.cdxgen = {
    displayName = "cdxgen";
    description = "Tool to create CycloneDX Software Bill-of-Materials (SBOM) for projects from source and container images.";
    longDescription = ''
      CLI tool, library, REPL, and server to create, validate, sign, and verify software BOMs.

      It generates CycloneDX JSON BOMs and supports SPDX 3.0.1 JSON-LD export.
    '';
    usage = ''
      ##### SBOM for local projects

      First, [launch the shell envrionment](app/${app.name}#run-shell) containing `${app.name}`.

      Then, navigate to the project you want to use.
      For the examples below, we will use the [`npm-smoke`](https://github.com/cdxgen/cdxgen/tree/${app.data.cdxgenCommit}/test/repotests/npm-smoke) test repository.
      You can either access it by cloning the `cdxgen` repository locally:

      ```
      git clone https://github.com/cdxgen/cdxgen
      cd cdxgen/test/repotests/npm-smoke
      ```

      or by using a tool like [degit](https://search.nixos.org/packages?channel=unstable&query=degit#show=degit) to only fetch the directories we need:

      ```bash
      degit cdxgen/cdxgen/test/repotests cdxgen-repotests
      cd cdxgen-repotests/npm-smoke
      ```

      Next, we will generate an SBOM for the project:

      ```bash
      cdxgen -t npm -o bom.json ./
      ```

      Open this file in your favorite editor and see the result.

      Feel free to experiment with other repositories and [repotests](https://github.com/cdxgen/cdxgen/tree/${app.data.cdxgenCommit}/test/repotests).

      ##### SBOM for OCI artifacts

      If the image is in the format of a `docker.io` prefix or has a `sha256`, it will be automatically considered as a `docker` type.
      If this isn't detected, you could also manually pass `-t docker`:

      ```bash
      cdxgen python:${app.data.ociPythonTag}-o bom-python-oci.json -t docker

      # or

      cdxgen \
        python:${app.data.ociPythonTag}@sha256:${app.data.ociPythonHash} \
        -o bom-python-oci.json \
        -t docker
      ```

      > [!NOTE]
      > If no tag is specified, the `latest` one will be used.

      We can also scan a local OCI artifact.
      For example, [build the `cdxgen` service container](http://127.0.0.1:3000/app/cdxgen#run-container), then scan the resulting tar file:

      ```bash
      cdxgen ~/.cache/ngi-forge/e70cdb81/cdxgen-cdxgen-3jv5dvlwc83xkbavgyvfbyr4j9w3acz2.tar -o bom-forge.json -t docker
      ```

      > [!NOTE]
      > The path to the tarball is just an example.
      > The real one will be printed when you build the container.

      ##### cdxgen server

      First, launch the HTTP server in [the NixOS](app/cdxgen#run-nixos) or [container](app/cdxgen#run-nixos) runtimes.
      By default, it will be accessible from `http://127.0.0.1:${app.data.mainPort}`, but you can change this from the application recipe.

      Next, to scan a local path, run the following:

      ```bash
      export PROJECT_PATH="/path/to/project"
      export PROJECT_TYPE="js"

      curl "http://127.0.0.1:${app.data.mainPort}/sbom?path=$PROJECT_PATH&multiProject=true&type=$PROJECT_TYPE"
      ```

      or, to scan a git repo:

      ```bash
      export REPO_URL="https://github.com/HooliCorp/vulnerable-aws-koa-app.git"
      export PROJECT_TYPE="js"

      curl "http://127.0.0.1:${app.data.mainPort}/sbom?url=$REPO_URL&multiProject=true&type=$PROJECT_TYPE"
      ```

      For more details and examples, please see the [project documentation](${config.apps.cdxgen.links.docs}).
      More specifically, the following pages:

      - [CLI Usage](https://cdxgen.github.io/cdxgen/#/CLI)
      - [Generate BOM for source code inputs](https://cdxgen.github.io/cdxgen/#/?id=generate-bom-for-source-code-inputs)
      - [Companion CLI tools](https://cdxgen.github.io/cdxgen/#/?id=companion-cli-tools)
      - [BOM Audit](https://cdxgen.github.io/cdxgen/#/BOM_AUDIT)
      - [Advanced Usage](https://cdxgen.github.io/cdxgen/#/?id=advanced-usage)
    '';

    data = {
      mainPort = "9090";
      cdxgenCommit = "1bbffbffbb3da6386310fcb2997c72cbf0c7ecb8";
      ociPythonTag = "3.14-slim";
      ociPythonHash = "810da6270e43d30a1f3e0e1eabbeb6fbd9d78ad9dd2e754d5297a3d6cb42df46";
    };

    links = {
      website = "https://cdxgen.github.io/cdxgen/";
      source = "https://github.com/cdxgen/cdxgen";
      docs = "https://cdxgen.github.io/cdxgen";
    };

    icon = ./icon.svg;

    ngi.grants = {
      Core = [
        "HBoM-cdxgen"
      ];
    };

    programs = {
      mainPackage = pkgs.cdxgen;
      packages = with pkgs; [
        cdxgen
      ];

      runtimes = {
        shell.enable = true;
        program.enable = true;
      };
    };

    services = {
      components.cdxgen = {
        process.command = pkgs.cdxgen;
        process.argv = [
          "--server"
          "--server-host"
          "0.0.0.0"
          "--server-port"
          "${app.data.mainPort}"
        ];
        # https://github.com/cdxgen/cdxgen/blob/v13.0.1/docs/ENV.md
        process.environment = {
          CDXGEN_DEBUG_MODE = "info"; # debug or verbose
          # Query public registries to resolve package licenses.
          # Disabled by default because it's time-consuming. See:
          # https://github.com/cdxgen/cdxgen/blob/v13.0.1/README.md#resolving-licenses
          FETCH_LICENSE = "false";
        };
        process.ports = [
          "${app.data.mainPort}:${app.data.mainPort}"
        ];
        healthcheck = {
          enable = true;
          test = [
            "${lib.getExe pkgs.curl}"
            "-fs"
            "http://localhost:${app.data.mainPort}/health"
          ];
          interval = "3s";
          timeout = "3s";
          startPeriod = "10s";
          retries = 10;
        };
      };

      runtimes = {
        container = {
          enable = true;
          components.cdxgen = {
            packages = with pkgs; [
              cdxgen
              coreutils
              bash
            ];
          };
        };

        nixos = {
          enable = true;
          packages = with pkgs; [
            cdxgen
          ];
        };
      };
    };

    test = {
      programs.script = ''
        cdxgen -t npm -o bom.json .
        grep -q '"bomFormat"' bom.json
      '';
      services.script = ''
        curl="curl --retry 10 --retry-max-time 120 --retry-all-errors"
        $curl "http://localhost:${app.data.mainPort}/sbom?path=${pkgs.cdxgen.src}/test/repotests/npm-smoke&type=npm"
      '';
    };
  };
}
