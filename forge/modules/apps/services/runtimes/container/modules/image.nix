# Arguments of `dockerTools.streamLayeredImage` for a service component.
{
  app,

  service,
  serviceName,
  runner,
  runtimeConfig ? {
    packages = [ ];
  },
  pkgs,
  lib,
  ...
}:
let
  configFiles = map (file: { inherit (file) path format; }) (
    lib.filter (file: file.enable) (lib.attrValues service.process.configData)
  );

  references = lib.filterAttrs (_: link: link != null) service.process.references;
in
{
  name = "${app.name}-${serviceName}";

  # Compose mounts these as `tmpfs`. They must also exist in the image, so that
  # the image can start without compose, for example with `podman run`.
  extraCommands = ''
    mkdir --mode=1777 tmp run
  '';

  contents =
    let
      uid = "1001";
      gid = "1001";
      etcFiles = pkgs.runCommand "etc-${serviceName}" { } ''
        mkdir -p $out/etc
        echo 'root:x:0:0:root:/root:/bin/sh' > $out/etc/passwd
        echo '${serviceName}:x:${uid}:${gid}:${serviceName}:${service.process.stateDir}:/sbin/nologin' >> $out/etc/passwd
        echo 'root:x:0:' > $out/etc/group
        echo '${serviceName}:x:${gid}:' >> $out/etc/group
        echo 'root:!:0::::::' > $out/etc/shadow
        echo '${serviceName}:!:1::::::' >> $out/etc/shadow
        echo 'hosts: files dns' > $out/etc/nsswitch.conf
      '';
    in
    pkgs.buildEnv {
      name = "runtime-bins";
      paths = [
        etcFiles
      ]
      ++ service.process.packages
      ++ runtimeConfig.packages
      ++ service.healthcheck.packages;
      pathsToLink = [
        "/bin"
        "/etc"
      ];
    };

  config = {
    Entrypoint = [ (lib.getExe runner) ];
    WorkingDir = service.process.stateDir;
    User = if service.process.user == "root" then "root" else serviceName;
    Volumes = {
      "${service.process.stateDir}" = { };
    };
    Env =
      let
        envAttrsToList = attrs: lib.mapAttrsToList (n: v: "${n}=${v}") attrs;
      in
      envAttrsToList service.process.environment;
    Labels = {
      ngi-forge = "true";
      "ngi-forge.type" = "component";
    }
    // lib.optionalAttrs (service.process.parameters != { }) {
      "ngi-forge.parameters" = builtins.toJSON service.process.parametersSchema;
    }
    // lib.optionalAttrs (configFiles != [ ]) {
      "ngi-forge.config-files" = builtins.toJSON configFiles;
    }
    // lib.optionalAttrs (references != { }) {
      "ngi-forge.references" = builtins.toJSON references;
    }
    // lib.filterAttrs (_: value: value != null) {
      "org.opencontainers.image.title" = app.displayName;
      "org.opencontainers.image.url" = app.links.website;
      "org.opencontainers.image.source" = app.links.source;
      "org.opencontainers.image.documentation" = app.links.docs;
    };
  };
}
