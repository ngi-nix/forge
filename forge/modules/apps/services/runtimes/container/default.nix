{
  forge-inputs,
  forge-lib,
  config,
  lib,
  system,

  app,
  pkgs,
  specialArgs,
  ...
}@args:
let
  enabledResources = app.services.result.enabledResources;

  runners = lib.mapAttrs (
    serviceName: service:
    import ../mkServiceRunner.nix {
      inherit lib pkgs service;
      name = "${app.name}-${serviceName}";
      setup = config.components.${serviceName}.setup or "";
      supervise = true;
    }
  ) app.services.components;
in
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
    };

    resources = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.nixosConfig = lib.mkOption {
            type = lib.types.deferredModule;
            default = { };
            description = ''
              Container runtime specific configuration.

              See the list of available
              [NixOS options](https://search.nixos.org/options) .
            '';
            example = lib.literalExpression ''
              {
                services.postgresql.enableTCPIP = true;
                services.postgresql.authentication = '''
                  local all all trust
                  host all all 0.0.0.0/0 trust
                  host all all ::0/0 trust
                ''';
              }
            '';
          };
        }
      );
      default = { };
      description = "Per-resource container runtime NixOS configuration.";
    };

    result = {
      nixosImages = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (attrsOf anything);
        description = "NixOS based OCI images built from resource configuration.";
      };

      processImages = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (attrsOf anything);
        description = "Single process OCI images built from component configurations.";
      };

      images = lib.mkOption {
        internal = true;
        type = with lib.types; lazyAttrsOf (attrsOf anything);
        description = "Unified image set combining component and resource OCI images.";
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
    result.processImages = lib.mapAttrs (
      name: service:
      let
        stream = pkgs.dockerTools.streamLayeredImage (
          import ./modules/image.nix (
            {
              inherit service;
              serviceName = name;
              runner = runners.${name};
            }
            // args
            // lib.optionalAttrs (config.components ? ${name}) {
              runtimeConfig = config.components.${name};
            }
          )
        );
      in
      {
        inherit stream;
        tag = stream.imageTag;
        copyToArchive = tar: "${stream} 2>/dev/null > ${tar}";
      }
    ) app.services.components;

    result.shellRunner = lib.mapAttrs (
      serviceName: service:
      let
        inherit (service.process) stateDir;
        componentPackages = service.process.packages;
        runtimeComponentPackages = config.components.${serviceName}.packages or [ ];
        binPaths = lib.makeBinPath ([ pkgs.coreutils ] ++ componentPackages ++ runtimeComponentPackages);
        environment = service.process.environment // {
          PATH = binPaths;
        };
        runner = runners.${serviceName};
        flags = [
          # Give the service only the environment of the component.
          "--clearenv"
        ]
        ++ lib.concatLists (
          lib.mapAttrsToList (name: value: [
            "--setenv"
            name
            value
          ]) environment
        )
        # Hide the files of the host. Each directory is an empty `tmpfs`.
        ++
          lib.concatMap
            (path: [
              "--tmpfs"
              path
            ])
            [
              "/nix"
              "/tmp"
              "/run"
              "/var"
              "/etc"
            ]
        ++ [
          # Make new `/dev` and `/proc` file systems for the sandbox.
          "--dev"
          "/dev"
          "--proc"
          "/proc"
          # Give read-only access to the store paths and to `/sys`.
          "--ro-bind"
          "/nix/store"
          "/nix/store"
          "--ro-bind"
          "/sys"
          "/sys"
          # Name resolution of the host. Skipped if the file does not exist.
          "--ro-bind-try"
          "/etc/resolv.conf"
          "/etc/resolv.conf"
          # Isolate the processes, the host name, the IPC objects and the
          # cgroups from the host. The network stays shared, thus the service
          # is available on the ports of the host.
          "--unshare-pid"
          "--unshare-uts"
          "--unshare-ipc"
          "--unshare-cgroup"
          # Stop the sandbox when the calling process stops.
          "--die-with-parent"
          # Make the state directory and start the service in it.
          "--dir"
          stateDir
          "--chdir"
          stateDir
        ];
      in
      pkgs.writeShellApplication {
        name = "${runner.name}-sandbox";
        runtimeInputs = [ pkgs.bubblewrap ];
        text = ''
          exec bwrap \
            ${lib.escapeShellArgs flags} \
            -- ${lib.getExe runner} "$@"
        '';
        meta.badPlatforms = lib.platforms.darwin; # bubblewrap is not available on macOS
      }
    ) app.services.components;

    result.nixosImages = lib.mapAttrs (
      name: resource:
      let
        nixosEval = forge-inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            (resource.nixosConfig)
            (config.resources.${name}.nixosConfig or { })
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
              services.journald.settings.Journal.Storage = "volatile";
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
        tag = forge-lib.nixStoreHash initScript;
        stream = pkgs.dockerTools.streamLayeredImage {
          name = "${app.name}-${name}";
          inherit tag;
          contents = [ initScript ];
          config = {
            Cmd = [ "/usr/sbin/init" ];
            Env = [
              "container=docker"
              "PATH=/usr/bin:/run/current-system/sw/bin/"
            ];
            StopSignal = "SIGRTMIN+3";
            Labels = {
              ngi-forge = "true";
              "ngi-forge.type" = "resource";
            };
          };
        };
      in
      {
        inherit tag stream;
        copyToArchive = tar: "${stream} 2>/dev/null > ${tar}";
      }
    ) enabledResources;

    result.images = config.result.processImages // config.result.nixosImages;

    result.build =
      let
        componentNames = lib.attrNames app.services.components;

        resourceNames = lib.attrNames enabledResources;

        resourceNamesByRole =
          role: lib.attrNames (lib.filterAttrs (_: resource: resource.role == role) enabledResources);

        # Forward endpoints to the host, in compose `HOST:CONTAINER[/udp]` format.
        forwardedPorts =
          name:
          map (
            endpoint:
            "${toString endpoint.forwardedPort}:${toString endpoint.port}"
            + lib.optionalString (endpoint.protocol == "udp") "/udp"
          ) app.services.result.endpoints.${name};

        dependsOnCondition =
          depName:
          if lib.hasAttr depName enabledResources then
            "service_healthy"
          else if app.services.components.${depName}.healthcheck.enable then
            "service_healthy"
          else
            "service_started";

        serviceComponents = lib.mapAttrs (
          name: service:
          {
            image = "localhost/${app.name}-${name}:${config.result.images.${name}.tag}";
            ports = forwardedPorts name;
            # Backend resources start before components, components depend on them.
            depends_on = lib.genAttrs (service.dependsOn ++ resourceNamesByRole "backend") (depName: {
              condition = dependsOnCondition depName;
            });
            tmpfs = [
              "/tmp:rw,size=64m"
              "/run:rw,size=64m"
            ];
            volumes = [ "${name}-data:${service.process.stateDir}" ];
            labels = [ "ngi-forge.type=component" ];
          }
          // lib.optionalAttrs service.healthcheck.enable {
            healthcheck = {
              test = [ "CMD" ] ++ service.healthcheck.test;
              interval = service.healthcheck.interval;
              timeout = service.healthcheck.timeout;
              start_period = service.healthcheck.startPeriod;
              retries = service.healthcheck.retries;
            };
          }
        ) app.services.components;

        resourceDefaultHealthcheck = {
          test = [
            # Check for system reaching multi-user target and make sure that no
            # unit is failing
            "CMD-SHELL"
            ''
              if systemctl is-active --quiet multi-user.target \
                && [ "$(systemctl list-units --state failed --output json)" = "[]" ]; then
                logger "Healthcheck: OK"
                exit 0
              else
                logger "Healthcheck: FAILED"
                exit 1
              fi
            ''
          ];
          interval = "5s";
          timeout = "5s";
          start_period = "30s";
          retries = 10;
        };

        resourcesComponents = lib.mapAttrs (name: resource: {
          image = "localhost/${app.name}-${name}:${config.result.images.${name}.tag}";
          ports = forwardedPorts name;
          # Frontend resources start after all components so that upstream
          # hostnames are registered in the container network DNS before the
          # resource process (e.g. nginx) performs its startup checks.
          depends_on = lib.optionalAttrs (resource.role == "frontend") (
            lib.genAttrs componentNames (depName: {
              condition = dependsOnCondition depName;
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
          healthcheck = resourceDefaultHealthcheck;
        }) enabledResources;

        composeFile = pkgs.writeText "${app.name}-compose.yaml" (
          lib.generators.toYAML { } {
            services = lib.foldl lib.recursiveUpdate { } [
              resourcesComponents
              serviceComponents
            ];
            volumes = lib.genAttrs' (componentNames ++ resourceNames) (
              name: lib.nameValuePair "${name}-data" { }
            );
          }
        );

        cacheDir = "\${XDG_CACHE_HOME:-$HOME/.cache}/ngi-forge/${
          lib.substring 0 8 (lib.hashString "md5" specialArgs.forgeConfig.forge.repositoryUrl)
        }";

        imageTar = name: tag: "$CACHE_DIR/${app.name}-${name}-${tag}.tar";

        build-oci-images = pkgs.writeShellScriptBin "build-oci-images" (
          ''
            CACHE_DIR="${cacheDir}"
            mkdir -p "$CACHE_DIR"
          ''
          + lib.concatMapAttrsStringSep "\n" (name: image: ''
            IMAGE_TAR="${imageTar name image.tag}"
            if [ ! -f "$IMAGE_TAR" ]; then
              printf "Creating container image %s ... " "$IMAGE_TAR"
              ${image.copyToArchive "$IMAGE_TAR"}
              echo "done."
            else
              echo "Image already exists in cache: $IMAGE_TAR"
            fi
          '') config.result.images
        );

        compose-file = pkgs.runCommand "compose-file" { } ''
          install -D ${composeFile} $out/${app.name}/compose.yaml
        '';

        run-podman = pkgs.writeShellScriptBin "run-podman" ''
          CACHE_DIR="${cacheDir}"
          ${lib.getExe build-oci-images}

          ${lib.concatMapAttrsStringSep "\n" (name: image: ''
            podman load --quiet < "${imageTar name image.tag}"
            podman tag ${app.name}-${name}:${image.tag} ${app.name}-${name}:latest
          '') config.result.images}

          ${lib.getExe pkgs.podman-compose} \
            -f ${compose-file}/${app.name}/compose.yaml \
            ''${COMPOSE_OVERRIDE_FILE:+-f "$COMPOSE_OVERRIDE_FILE"} \
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
