{
  forge-inputs,
  config,
  lib,
  system,

  app,
  pkgs,
  specialArgs,
  ...
}@args:
{
  options = {
    enable = lib.mkEnableOption "Container runtime";

    composeFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the custom container compose file.
        Set to null to automatically generate this file.
      '';
      example = lib.literalExpression "./compose.yaml";
    };

    components = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          inherit specialArgs;
          modules = [
            {
              options = {
                setup = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                  description = ''
                    Script to run once at the container startup.
                    Use this option for one-off system preparation steps.
                  '';
                  example = ''
                    # bash
                    echo "Creating directory structure ..."
                    mkdir --parents /var/lib/myservice/config /var/lib/myservice/db
                  '';
                };

                packages = lib.mkOption {
                  type = lib.types.listOf lib.types.package;
                  default = [ ];
                  description = ''
                    List of packages available in the container.

                    Use this option to add packages required by setup script.
                  '';
                  example = lib.literalExpression "[ pkgs.curl ]";
                };

                imageConfig = lib.mkOption {
                  type = with lib.types; lazyAttrsOf anything;
                  default = { };
                  description = ''
                    OCI image configuration.

                    See the list of available
                    [OCI image configuration options](https://specs.opencontainers.org/image-spec/config/#properties) .
                  '';
                  example = lib.literalExpression ''
                    {
                      WorkingDir = "/var/lib/myservice";
                    }
                  '';
                };
              };
            }
          ];
        }
      );
      default = { };
      description = "Per-component container runtime configuration.";
      apply =
        self:
        let
          knownComponents = lib.attrNames app.services.components;
          unknownComponents = lib.subtractLists knownComponents (lib.attrNames self);
        in
        lib.throwIf (unknownComponents != [ ])
          "services.runtimes.container.components: unknown component(s): ${lib.concatStringsSep ", " unknownComponents}. Must be one of: ${lib.concatStringsSep ", " knownComponents}"
          self;
    };

    extraComponents = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          inherit specialArgs;
          modules = [
            {
              options = {
                nixosConfig = lib.mkOption {
                  type = with lib.types; deferredModule;
                  default = { };
                  description = "Container runtime-specific NixOS system configuration overrides.";
                };
              };
            }
          ];
        }
      );
      default = { };
      description = ''
        Container runtime-specific overrides for extra components.
        Use this to configure settings that are only applicable when running the component in a systemd-powered container (e.g., enabling TCP/IP for local container networking).
      '';
      apply =
        self:
        let
          knownComponents = lib.attrNames app.services.extraComponents;
          unknownComponents = lib.subtractLists knownComponents (lib.attrNames self);
        in
        lib.throwIf (unknownComponents != [ ])
          "services.runtimes.container.extraComponents: unknown extraComponent(s): ${lib.concatStringsSep ", " unknownComponents}. Must be one of: ${lib.concatStringsSep ", " knownComponents}"
          self;
    };

    result = {
      modules = lib.mkOption {
        internal = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "Nimi configuration.";
      };

      evals = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "Nimi module evaluation.";
      };

      arionEval = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "Arion module evaluation.";
      };

      recipes = lib.mkOption {
        internal = true;
        type = with lib.types; lazyAttrsOf (nullOr package);
        default = null;
        description = "Script that builds container image recipe.";
      };

      build = lib.mkOption {
        internal = true;
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Script that builds container image.";
      };

      shellRunner = lib.mkOption {
        internal = true;
        type = with lib.types; lazyAttrsOf (nullOr package);
        default = { };
        description = "Per-service bubblewrap-sandboxed runner.";
      };

      # HACK:
      # Prevent toJSON conversion from attempting to convert the `eval` option,
      # which won't work because it's a whole NixOS evaluation.
      __toString = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; functionTo str;
        default = self: "container";
      };
    };
  };

  config = {
    result.modules = lib.mapAttrs (serviceName: service: {
      settings = import ./modules/settings.nix (
        {
          inherit service serviceName;
        }
        // args
        // lib.optionalAttrs (config.components ? ${serviceName}) {
          runtimeConfig = config.components.${serviceName};
        }
      );
      services = import ../mkNimiImports.nix { inherit lib service serviceName; };
    }) app.services.components;

    result.evals = lib.mapAttrs (
      name: value:
      forge-inputs.nimi.packages.${system}.nimi.passthru.evalNimiModule {
        config = config.result.modules.${name};
      }
    ) app.services.components;

    result.recipes = lib.mapAttrs (
      name: value:
      forge-inputs.nimi.packages.${system}.nimi.mkContainerImage {
        config = config.result.modules.${name};
      }
    ) app.services.components;

    result.shellRunner = lib.mapAttrs (
      serviceName: service:
      let
        componentPackages = service.packages;
        runtimeComponentPackages = config.components.${serviceName}.packages or [ ];
        binPaths = lib.makeBinPath ([ pkgs.coreutils ] ++ componentPackages ++ runtimeComponentPackages);
      in
      forge-inputs.nimi.packages.${system}.nimi.mkBwrap {
        settings.bubblewrap.environment = service.environment // {
          PATH = binPaths;
        };
        settings.bubblewrap.prependFlags = [ "--clearenv" ];
        settings.bubblewrap.chdir = "/var/lib/${serviceName}";
        settings.bubblewrap.unshare.user = false;
        settings.bubblewrap.appendFlags = [
          "--dir"
          "/var/lib/${serviceName}"
        ];
        imports = [ { inherit (config.result.modules.${serviceName}) services settings; } ];
      }
    ) app.services.components;

    result.arionEval = forge-inputs.arion.lib.eval {
      inherit pkgs;
      modules = [
        {
          project.name = app.name;
          services = lib.mapAttrs (name: value: {
            nixos.useSystemd = true;
            nixos.configuration = {
              imports = [
                {
                  system.disableInstallerTools = true;
                  system.switch.enable = false;
                  nix.enable = false;
                  systemd.oomd.enable = false;
                  boot.tmp.useTmpfs = true;
                  networking.useDHCP = false;
                  services.nscd.enable = false;
                  system.nssModules = lib.mkForce [ ];
                  system.stateVersion = "26.05";
                }
                value.nixosConfig
                (config.extraComponents.${name}.nixosConfig or { })
              ];
            };
            service.ports = value.ports;
            service.useHostStore = false;
          }) app.services.extraComponents;
        }
      ];
    };

    result.build =
      let
        effectiveComposeFile =
          if config.composeFile != null then
            config.composeFile
          else
            pkgs.writeText "${app.name}-compose.yaml" (
              lib.generators.toYAML { } {
                services = lib.mapAttrs (name: service: {
                  image = "localhost/${name}:latest";
                  ports = service.ports;
                  depends_on = lib.genAttrs service.after (_name: { });
                  tmpfs = [
                    "/tmp:rw,size=64m"
                    "/run:rw,size=64m"
                  ];
                  volumes = [ "${name}-data:${service.stateDir}" ];
                }) app.services.components;
                volumes = lib.mapAttrs' (name: _: lib.nameValuePair "${name}-data" { }) app.services.components;
              }
            );

        build-oci-images = pkgs.writeShellScriptBin "build-oci-images" (
          lib.concatMapAttrsStringSep "\n" (name: value: ''
            ${value.copyTo}/bin/copy-to oci-archive:${name}.tar:${name}:latest
            echo "Created container image in $(pwd)/${name}.tar"
          '') config.result.recipes
        );

        compose-file = pkgs.runCommand "compose-file" { } ''
          install -D ${effectiveComposeFile} $out/${app.name}/compose.yaml
        '';

        hasExtraComponents = app.services.extraComponents != { };
        arionComposeFile = config.result.arionEval.config.out.dockerComposeYaml;
        arionImages =
          if hasExtraComponents then
            lib.concatMapStringsSep "\n" (name: ''
              ${config.result.arionEval.config.services.${name}.build.image} | podman load
            '') (lib.attrNames app.services.extraComponents)
          else
            "";

        cacheDir = "\${XDG_CACHE_HOME:-$HOME/.cache}/ngi-forge/${builtins.hashString "md5" specialArgs.forgeConfig.forge.repositoryUrl}/tmp";

        run-podman = pkgs.writeShellScriptBin "run-podman" ''
          CACHE_DIR="${cacheDir}"
          mkdir -p "$CACHE_DIR"
          TMPDIR=$(mktemp -d -p "$CACHE_DIR")

          trap 'rm -rf "$TMPDIR"' EXIT

          pushd $TMPDIR
            ${lib.getExe build-oci-images}

            for image in *.tar; do
              [ -e "$image" ] || continue
              podman load < "$image"
              rm "$image"
            done
            ${arionImages}
          popd

          ${lib.getExe pkgs.podman-compose} \
            -f ${compose-file}/${app.name}/compose.yaml \
            ${lib.optionalString hasExtraComponents "-f ${arionComposeFile}"} \
            up --force-recreate "$@"
        '';

        run-container = pkgs.writeShellScriptBin "run-container" ''
          set -euo pipefail
          ${arionImages}

          # start the containers
          ${lib.getExe run-podman} "$@"
        '';
      in
      pkgs.symlinkJoin {
        name = "run-container";
        paths = [
          build-oci-images
          compose-file
          run-podman
          run-container
        ];
        meta.mainProgram = "run-container";
      };
  };
}
