{
  config,
  lib,

  nimi,
  app,
  pkgs,
  ...
}@args:
{
  options = {
    enable = lib.mkEnableOption "container image output";

    composeFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the application container's compose file. When null, a default compose file is generated.";
    };

    components = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            setup = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Script to run once at container startup.";
            };

            tag = lib.mkOption {
              type = lib.types.str;
              default = "latest";
              description = "Tag of the generated container.";
            };

            packages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = "List of packages to add to the container's `/bin` directory.";
            };

            # NOTE: config is reserved by the module system
            extraConfig = lib.mkOption {
              type = with lib.types; lazyAttrsOf anything;
              default = { };
              description = ''
                OCI image configuration as specified in <https://specs.opencontainers.org/image-spec/config/#properties>.
              '';
            };
          };
        }
      );
      default = { };
      description = "Per-component container configuration.";
      apply =
        self:
        let
          unknownComponents = lib.subtractLists (lib.attrNames app.services.components) (lib.attrNames self);
        in
        if unknownComponents != [ ] then
          throw "services.runtimes.container.components: unknown component(s): ${lib.concatStringsSep ", " unknownComponents}. Must be one of: ${lib.concatStringsSep ", " (lib.attrNames app.services.components)}"
        else
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
        args
        // {
          inherit service;
          componentConfig =
            config.components.${serviceName} or {
              setup = "";
              packages = [ ];
              extraConfig = { };
            };
        }
      );
      services = import ../mkNimiImports.nix { inherit lib service serviceName; };
    }) app.services.components;

    result.evals = lib.mapAttrs (
      name: value: nimi.passthru.evalNimiModule { config = config.result.modules.${name}; }
    ) app.services.components;

    result.recipes = lib.mapAttrs (
      name: value: nimi.mkContainerImage { config = config.result.modules.${name}; }
    ) app.services.components;

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
                  ports = app.services.ports ++ service.ports;
                }) app.services.components;
              }
            );

        build-oci-images = pkgs.writeShellScriptBin "build-oci-images" (
          lib.concatMapAttrsStringSep "\n" (name: value: ''
            ${value.copyTo}/bin/copy-to oci-archive:${name}.tar:${name}:${
              config.components.${name}.tag or "latest"
            }
            echo "Created container image in $(pwd)/${name}.tar"
          '') config.result.recipes
        );

        compose-file = pkgs.runCommand "compose-file" { } ''
          install -D ${effectiveComposeFile} $out/${app.name}/compose.yaml
        '';

        run-podman = pkgs.writeShellScriptBin "run-podman" ''
          TMPDIR=$(mktemp -d)

          trap 'rm -rf "$TMPDIR"' EXIT

          pushd $TMPDIR
            ${lib.getExe build-oci-images}

            for image in *.tar; do
              podman load < "$image"
              rm "$image"
            done
          popd

          ${lib.getExe pkgs.podman-compose} \
            -f ${compose-file}/${app.name}/compose.yaml \
            up --force-recreate "$@"
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
