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

    resources = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ../../resource.nix);
      default = { };
      description = "Per-resource container runtime NixOS configuration.";
      apply =
        self:
        let
          knownResources = lib.concatMap (c: lib.attrNames c.resources) (
            lib.attrValues app.services.components
          );
          unknownResources = lib.subtractLists knownResources (lib.attrNames self);
        in
        lib.throwIf (unknownResources != [ ])
          "services.runtimes.container.resources: unknown resource(s): ${lib.concatStringsSep ", " unknownResources}. Must be one of: ${lib.concatStringsSep ", " (lib.unique knownResources)}"
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

      nixosImages = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf package;
        description = "OCI images built from NixOS configurations for resource components.";
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
      name: _:
      forge-inputs.nimi.packages.${system}.nimi.passthru.evalNimiModule {
        config = config.result.modules.${name};
      }
    ) app.services.components;

    result.recipes = lib.mapAttrs (
      name: _:
      forge-inputs.nimi.packages.${system}.nimi.mkContainerImage {
        config = config.result.modules.${name};
      }
    ) app.services.components;

    result.shellRunner = lib.mapAttrs (
      serviceName: service:
      let
        componentPackages = service.process.packages;
        runtimeComponentPackages = config.components.${serviceName}.packages or [ ];
        binPaths = lib.makeBinPath ([ pkgs.coreutils ] ++ componentPackages ++ runtimeComponentPackages);
      in
      forge-inputs.nimi.packages.${system}.nimi.mkBwrap {
        settings.bubblewrap.environment = service.process.environment // {
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

    result.nixosImages = lib.mapAttrs (
      name: resource:
      let
        nixosEval = forge-inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            (resource.nixosConfig)
            (pkgs.path + "/nixos/modules/profiles/minimal.nix")
            {
              boot.isContainer = true;
              boot.specialFileSystems = lib.mkForce { };
              boot.nixStoreMountOpts = lib.mkForce [ ];
              networking.hostName = "";
              networking.useDHCP = false;
              networking.resolvconf.enable = false;
              environment.etc.hosts.enable = false;
              systemd.services.systemd-logind.enable = false;
              systemd.services.console-getty.enable = false;
              systemd.sockets.nix-daemon.enable = lib.mkDefault false;
              systemd.services.nix-daemon.enable = lib.mkDefault false;
              systemd.oomd.enable = false;
              system.nssModules = lib.mkForce [ ];
              system.disableInstallerTools = true;
              system.switch.enable = false;
              services.nscd.enable = false;
              services.journald.extraConfig = ''
                Storage=volatile
              '';
              system.activationScripts.logs-hint.text = ''
                echo "Run 'podman exec \$(podman ps -qf name=${app.name}_${name}) journalctl -f' to see more logs ..."
              '';

              nix.enable = false;
              system.stateVersion = "26.05";
            }
          ];
        };
        toplevel = nixosEval.config.system.build.toplevel;
        initScript = pkgs.runCommand "${name}-init" { } ''
          mkdir -p $out/usr/sbin
          ln -s ${toplevel}/init $out/usr/sbin/init
        '';
      in
      pkgs.dockerTools.streamLayeredImage {
        inherit name;
        tag = "latest";
        contents = [ initScript ];
        config = {
          Cmd = [ "/usr/sbin/init" ];
          Env = [
            "container=docker"
            "PATH=/usr/bin:/run/current-system/sw/bin/"
          ];
          StopSignal = "SIGRTMIN+3";
        };
      }
    ) app.services.resources;

    result.build =
      let
        # Collect frontend resources and the components that declare them as such.
        # Result: { <resource-name> = [ <component-name> ... ]; }
        # Frontend resources start after these components so that upstream
        # hostnames are registered in the container network DNS before the
        # resource process (e.g. nginx) performs its startup checks.
        frontendResourceDeps = lib.foldlAttrs (
          acc: cname: comp:
          lib.foldlAttrs (
            acc2: rname: r:
            if r.role == "frontend" then acc2 // { ${rname} = (acc2.${rname} or [ ]) ++ [ cname ]; } else acc2
          ) acc comp.resources
        ) { } app.services.components;

        # Backend resources start before components — components depend on them.
        backendResourceNames = lib.filter (rname: !(lib.hasAttr rname frontendResourceDeps)) (
          lib.attrNames app.services.resources
        );

        serviceComponents = lib.mapAttrs (name: service: {
          image = "localhost/${name}:latest";
          ports = service.process.ports;
          depends_on = lib.genAttrs (service.dependsOn ++ backendResourceNames) (_name: {
            condition = "service_started";
          });
          tmpfs = [
            "/tmp:rw,size=64m"
            "/run:rw,size=64m"
          ];
          volumes = [ "${name}-data:${service.process.stateDir}" ];
          labels = [ "ngi-forge.type=component" ];
        }) app.services.components;

        resourcesComponents = lib.mapAttrs (name: resource: {
          image = "localhost/${name}:latest";
          ports = resource.ports;
          depends_on = lib.optionalAttrs (lib.hasAttr name frontendResourceDeps) (
            lib.genAttrs frontendResourceDeps.${name} (_: {
              condition = "service_started";
            })
          );
          tmpfs = [
            "/run"
            "/run/wrappers"
          ];
          volumes = [ "${name}-data:/var/lib" ];
          cap_add = [ "SYS_ADMIN" ];
          stop_signal = "SIGRTMIN+3";
          stop_grace_period = "30s";
          labels = [ "ngi-forge.type=resource" ];
        }) app.services.resources;

        composeFile = pkgs.writeText "${app.name}-compose.yaml" (
          lib.generators.toYAML { } {
            services = lib.foldl lib.recursiveUpdate { } [
              resourcesComponents
              serviceComponents
            ];
            volumes =
              lib.mapAttrs' (name: _: lib.nameValuePair "${name}-data" { }) app.services.components
              // lib.mapAttrs' (name: _: lib.nameValuePair "${name}-data" { }) app.services.resources;
          }
        );

        cacheDir = "\${XDG_CACHE_HOME:-$HOME/.cache}/ngi-forge/${lib.hashString "md5" specialArgs.forgeConfig.forge.repositoryUrl}";

        imageHash = drv: lib.unsafeDiscardStringContext (lib.substring 0 32 (baseNameOf drv.outPath));

        imageTar = name: drv: "$CACHE_DIR/${name}-${imageHash drv}.tar";

        build-oci-images = pkgs.writeShellScriptBin "build-oci-images" (
          ''
            CACHE_DIR="${cacheDir}"
            mkdir -p "$CACHE_DIR"
          ''
          + lib.concatMapAttrsStringSep "\n" (name: recipe: ''
            IMAGE_TAR="${imageTar name recipe}"
            if [ ! -f "$IMAGE_TAR" ]; then
              printf "Creating container image %s ... " "$IMAGE_TAR"
              ${recipe.copyTo}/bin/copy-to oci-archive:$IMAGE_TAR:${name}:latest >/dev/null
              echo "done."
            else
              echo "Image already exists in cache: $IMAGE_TAR"
            fi
          '') config.result.recipes
          + lib.concatMapAttrsStringSep "\n" (name: imageStream: ''
            IMAGE_TAR="${imageTar name imageStream}"
            if [ ! -f "$IMAGE_TAR" ]; then
              printf "Creating container image %s ... " "$IMAGE_TAR"
              ${imageStream} 2>/dev/null > "$IMAGE_TAR"
              echo "done."
            else
              echo "Image already exists in cache: $IMAGE_TAR"
            fi
          '') config.result.nixosImages
        );

        compose-file = pkgs.runCommand "compose-file" { } ''
          install -D ${composeFile} $out/${app.name}/compose.yaml
        '';

        run-podman = pkgs.writeShellScriptBin "run-podman" ''
          CACHE_DIR="${cacheDir}"

          ${lib.getExe build-oci-images}

          IMAGES=(
            ${lib.concatMapAttrsStringSep "\n    " (
              name: recipe: "\"${imageTar name recipe}\""
            ) config.result.recipes}
            ${lib.concatMapAttrsStringSep "\n    " (
              name: imageStream: "\"${imageTar name imageStream}\""
            ) config.result.nixosImages}
          )
          for image in "''${IMAGES[@]}"; do
            podman load --quiet < "$image"
          done

          ${lib.getExe pkgs.podman-compose} \
            -f ${compose-file}/${app.name}/compose.yaml \
            up --force-recreate --remove-orphans "$@"
        '';

        run-container = pkgs.writeShellScriptBin "run-container" ''
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
