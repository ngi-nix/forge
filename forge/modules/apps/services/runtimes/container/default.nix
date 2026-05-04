{
  inputs,
  config,
  lib,
  system,

  app,
  pkgs,
  ...
}@args:
let
  nimi = inputs.ngi-forge.inputs.nimi.packages.${system}.nimi;
in
{
  options = {
    enable = lib.mkEnableOption "container image output";

    setup = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Script to run once at startup.";
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

    composeFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the application container's compose file. When null, a default compose file is generated.";
    };

    result = {
      modules = lib.mkOption {
        internal = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "Nimi configuration.";
      };

      eval = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "Nimi module evaluation.";
      };

      recipe = lib.mkOption {
        internal = true;
        type = lib.types.nullOr lib.types.package;
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
    result.modules = {
      settings = import ./modules/settings.nix args;
      services = import ./modules/services.nix args;
    };

    result.eval = nimi.passthru.evalNimiModule { config = config.result.modules; };

    result.recipe = nimi.mkContainerImage { config = config.result.modules; };

    result.build =
      let
        effectiveComposeFile =
          if config.composeFile != null then
            config.composeFile
          else
            pkgs.writeText "${app.name}-compose.yaml" ''
              services:
                ${app.name}:
                  image: localhost/${app.name}:latest
            '';
        build-oci-image = pkgs.writeShellScriptBin "build-oci-image" ''
          ${config.result.recipe.copyTo}/bin/copy-to \
            oci-archive:${app.name}.tar:${app.name}:${config.tag}
          echo "Container image created in $(pwd)/${app.name}.tar ."
        '';
        compose-file = pkgs.runCommand "compose-file" { } ''
          mkdir -p $out/${app.name}
          cp ${effectiveComposeFile} $out/${app.name}/compose.yaml
        '';
        run-podman = pkgs.writeShellScriptBin "run-podman" ''
          ${lib.getExe build-oci-image}
          podman load <${app.name}.tar
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
          build-oci-image
          compose-file
          run-podman
          run-container
        ];
        meta.mainProgram = "run-container";
      };
  };
}
