{
  config,
  lib,

  arion,
  app,
  pkgs,
  ...
}@args:
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
      composition = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; lazyAttrsOf (either attrs anything);
        description = "Arion composition evaluation.";
      };

      build = lib.mkOption {
        internal = true;
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Script that runs the container.";
      };

      # HACK:
      # Prevent toJSON conversion from attempting to convert the `composition` option,
      # which won't work because it's a whole module evaluation.
      __toString = lib.mkOption {
        internal = true;
        readOnly = true;
        type = with lib.types; functionTo str;
        default = self: "container";
      };
    };
  };

  config = {
    result.composition = arion.lib.eval {
      inherit pkgs;
      modules = [
        (import ./modules/settings.nix args)
        (import ./modules/services.nix args)
      ];
    };

    result.build =
      let
        composition = config.result.composition;
        composeYaml =
          if config.composeFile != null
          then config.composeFile
          else composition.config.out.dockerComposeYaml;

        loadImages = pkgs.writeShellScript "load-images" (
          lib.concatMapStrings (
            img:
            if img ? imageExe
            then "${img.imageExe} | podman load\n"
            else "podman load < ${img.image}\n"
          ) composition.config.build.imagesToLoad
        );

        run-container = pkgs.writeShellScriptBin "run-container" ''
          ${loadImages}
          ${lib.getExe pkgs.podman-compose} \
            -f ${composeYaml} \
            up --force-recreate "$@"
        '';
      in
      pkgs.symlinkJoin {
        name = "run-container";
        paths = [ run-container ];
        meta.mainProgram = "run-container";
      };
  };
}
